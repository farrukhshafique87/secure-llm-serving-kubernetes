#!/usr/bin/env bash
# EXP-07 on Amazon EKS (methodology §16): cluster, Calico (policy only), default
# StorageClass, metrics-server and the k6 VM. Run from the repository root on
# the PC; re-runnable, every step is skipped when its result already exists.
# Remove everything again with cloud/eks-down.sh.
#
# Needs: aws CLI v2 with credentials of the AWS project, eksctl, kubectl.
# Writes: ~/.ssh/thesis-k6.pem (key of the k6 VM, never into the repository).
set -euo pipefail

cd "$(dirname "$0")/.."

# One setup or teardown at a time: a second start waits for the first, then
# re-runs (every step is skipped when its result exists).
exec 8>/tmp/thesis-cloud.lock
if ! flock -n 8; then
  echo "== another eks-up.sh or eks-down.sh is running; waiting until it ends ($(date -Is))"
  flock 8
fi
REGION=eu-north-1
ZONE=eu-north-1a
CLUSTER=thesis-eks
VM_TYPE=m7i-flex.large   # largest Free plan type, as the nodes
VM_NAME=thesis-k6
ROLE=thesis-k6-vm
KEY=thesis-k6
KEY_FILE="$HOME/.ssh/$KEY.pem"
CALICO_VERSION="${CALICO_VERSION:-v3.32.2}"   # as on Kind (scripts/kind-up.sh)
TAG="ResourceType=instance,Tags=[{Key=Name,Value=$VM_NAME},{Key=project,Value=thesis-exp07}]"
export AWS_REGION="$REGION"
unset AWS_ENDPOINT_URL

echo "== pre-checks"
aws sts get-caller-identity --query Arn --output text
QUOTA=$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A \
  --query Quota.Value --output text)
echo "on-demand vCPU quota: $QUOTA (needed: 6)"
awk -v q="$QUOTA" 'BEGIN { exit !(q >= 6) }' || { echo "ERROR: vCPU quota below 6" >&2; exit 1; }
aws eks describe-cluster-versions --query "clusterVersions[].clusterVersion" --output text \
  | tr '\t' '\n' | grep -qx 1.36 || { echo "ERROR: EKS 1.36 not offered" >&2; exit 1; }
echo "Check the remaining credit before going on: AWS project settings -> Billing."

echo "== cluster (15-20 min on first run)"
if ! aws eks describe-cluster --name "$CLUSTER" >/dev/null 2>&1; then
  eksctl create cluster -f cloud/eks-cluster.yaml
fi
# On a re-run (for example after a failed node group): remove the stack of a
# node group that failed (eksctl protects its stacks against deletion), then
# create what is missing.
for ng in inference api; do
  STACK="eksctl-$CLUSTER-nodegroup-$ng"
  if [ "$(aws cloudformation describe-stacks --stack-name "$STACK" \
        --query "Stacks[0].StackStatus" --output text 2>/dev/null)" = ROLLBACK_COMPLETE ]; then
    aws cloudformation update-termination-protection --stack-name "$STACK" --no-enable-termination-protection >/dev/null
    aws cloudformation delete-stack --stack-name "$STACK"
    aws cloudformation wait stack-delete-complete --stack-name "$STACK"
  fi
done
eksctl create nodegroup -f cloud/eks-cluster.yaml   # skips existing node groups
if ! aws eks describe-addon --cluster-name "$CLUSTER" --addon-name aws-ebs-csi-driver >/dev/null 2>&1; then
  eksctl create addon -f cloud/eks-cluster.yaml
fi
aws eks update-kubeconfig --name "$CLUSTER" --alias "$CLUSTER" >/dev/null
kubectl get nodes -L role

echo "== default StorageClass"
kubectl apply -f cloud/eks-storageclass.yaml
if kubectl get storageclass gp2 >/dev/null 2>&1; then
  kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class=false --overwrite
fi

echo "== Calico $CALICO_VERSION, policy only"
if ! kubectl get ns calico-system >/dev/null 2>&1; then
  kubectl create -f \
    "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
  until kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; do sleep 2; done
  kubectl wait --for=condition=established crd/installations.operator.tigera.io --timeout=90s
  kubectl apply -f cloud/eks-calico-installation.yaml
fi
until kubectl get ns calico-system >/dev/null 2>&1; do sleep 5; done
kubectl -n calico-system rollout status ds/calico-node --timeout=300s

echo "== metrics-server (EKS has none; same version as on Kind)"
./scripts/install-metrics-server.sh

echo "== k6 VM: role with access to the cluster (no access keys on the VM)"
if ! aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
  aws iam create-role --role-name "$ROLE" --assume-role-policy-document \
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    >/dev/null
  aws iam put-role-policy --role-name "$ROLE" --policy-name describe-cluster --policy-document \
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"eks:DescribeCluster","Resource":"*"}]}'
  aws iam create-instance-profile --instance-profile-name "$ROLE" >/dev/null
  aws iam add-role-to-instance-profile --instance-profile-name "$ROLE" --role-name "$ROLE"
  sleep 10   # the instance profile needs a moment before EC2 accepts it
fi
ROLE_ARN=$(aws iam get-role --role-name "$ROLE" --query Role.Arn --output text)
if ! aws eks describe-access-entry --cluster-name "$CLUSTER" --principal-arn "$ROLE_ARN" >/dev/null 2>&1; then
  aws eks create-access-entry --cluster-name "$CLUSTER" --principal-arn "$ROLE_ARN" >/dev/null
  aws eks associate-access-policy --cluster-name "$CLUSTER" --principal-arn "$ROLE_ARN" \
    --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
    --access-scope type=cluster >/dev/null
fi

echo "== k6 VM: key, network, instance"
if [ ! -f "$KEY_FILE" ]; then
  aws ec2 delete-key-pair --key-name "$KEY" >/dev/null 2>&1 || true
  mkdir -p "$HOME/.ssh"
  aws ec2 create-key-pair --key-name "$KEY" --query KeyMaterial --output text > "$KEY_FILE"
  chmod 600 "$KEY_FILE"
fi
VPC=$(aws eks describe-cluster --name "$CLUSTER" --query cluster.resourcesVpcConfig.vpcId --output text)
CLUSTER_SG=$(aws eks describe-cluster --name "$CLUSTER" \
  --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
SUBNET=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC" "Name=availability-zone,Values=$ZONE" \
  "Name=map-public-ip-on-launch,Values=true" --query "Subnets[0].SubnetId" --output text)
SSH_SG=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" "Name=group-name,Values=$VM_NAME-ssh" \
  --query "SecurityGroups[0].GroupId" --output text)
if [ "$SSH_SG" = "None" ]; then
  SSH_SG=$(aws ec2 create-security-group --vpc-id "$VPC" --group-name "$VM_NAME-ssh" \
    --description "SSH to the k6 VM from the PC only" --query GroupId --output text)
fi
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id "$SSH_SG" --protocol tcp --port 22 \
  --cidr "$MY_IP/32" >/dev/null 2>&1 || true
VM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$VM_NAME" \
  "Name=instance-state-name,Values=pending,running,stopped" --query "Reservations[].Instances[0].InstanceId" --output text)
if [ -z "$VM" ] || [ "$VM" = "None" ]; then
  AMI=$(aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
    --query Parameter.Value --output text)
  # The cluster security group admits all traffic from its members, so the VM
  # reaches NodePort 30010 and Traefik's ports 80 and 443 on the nodes.
  VM=$(aws ec2 run-instances --image-id "$AMI" --instance-type "$VM_TYPE" --key-name "$KEY" \
    --subnet-id "$SUBNET" --security-group-ids "$CLUSTER_SG" "$SSH_SG" \
    --iam-instance-profile "Name=$ROLE" --tag-specifications "$TAG" \
    --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}' \
    --query "Instances[0].InstanceId" --output text)
fi
aws ec2 wait instance-running --instance-ids "$VM"
VM_IP=$(aws ec2 describe-instances --instance-ids "$VM" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
API_IP=$(kubectl get nodes -l role=api \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo
echo "== ready"
echo "k6 VM:    $VM ($VM_IP)  ssh -i $KEY_FILE ubuntu@$VM_IP"
echo "api node: $API_IP (entry for cloud-entry.sh)"
echo "Next: scp cloud/k6-vm-setup.sh to the VM and run it with API_IP=$API_IP."
