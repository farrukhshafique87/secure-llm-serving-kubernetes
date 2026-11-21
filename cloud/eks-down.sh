#!/usr/bin/env bash
# EXP-07 on Amazon EKS: delete everything cloud/eks-up.sh created, so the credit
# stops being used. Copy the results from the k6 VM first. Re-runnable.
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
CLUSTER=thesis-eks
VM_NAME=thesis-k6
ROLE=thesis-k6-vm
KEY=thesis-k6
export AWS_REGION="$REGION"
unset AWS_ENDPOINT_URL

echo "== k6 VM"
VM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$VM_NAME" \
  "Name=instance-state-name,Values=pending,running,stopped" --query "Reservations[].Instances[0].InstanceId" --output text)
if [ -n "$VM" ] && [ "$VM" != "None" ]; then
  aws ec2 terminate-instances --instance-ids "$VM" >/dev/null
  aws ec2 wait instance-terminated --instance-ids "$VM"
fi
aws ec2 delete-key-pair --key-name "$KEY" >/dev/null 2>&1 || true
rm -f "$HOME/.ssh/$KEY.pem"

echo "== volumes of the workloads (deleted with their claims, before the cluster)"
if aws eks describe-cluster --name "$CLUSTER" >/dev/null 2>&1; then
  aws eks update-kubeconfig --name "$CLUSTER" --alias "$CLUSTER" >/dev/null
  kubectl delete pvc --all -A --wait=true --timeout=300s || true
  VPC=$(aws eks describe-cluster --name "$CLUSTER" --query cluster.resourcesVpcConfig.vpcId --output text)
  SSH_SG=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" "Name=group-name,Values=$VM_NAME-ssh" \
    --query "SecurityGroups[0].GroupId" --output text)
  [ "$SSH_SG" != "None" ] && aws ec2 delete-security-group --group-id "$SSH_SG" || true
  ROLE_ARN=$(aws iam get-role --role-name "$ROLE" --query Role.Arn --output text 2>/dev/null || true)
  [ -n "$ROLE_ARN" ] && aws eks delete-access-entry --cluster-name "$CLUSTER" --principal-arn "$ROLE_ARN" || true

  echo "== cluster (10-15 min)"
  eksctl delete cluster -f cloud/eks-cluster.yaml --wait
fi

echo "== role of the k6 VM"
if aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
  aws iam remove-role-from-instance-profile --instance-profile-name "$ROLE" --role-name "$ROLE" || true
  aws iam delete-instance-profile --instance-profile-name "$ROLE" || true
  aws iam delete-role-policy --role-name "$ROLE" --policy-name describe-cluster || true
  aws iam delete-role --role-name "$ROLE"
fi

echo "== left over (should all be empty)"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending,running,stopped" \
  --query "Reservations[].Instances[].InstanceId" --output text
aws ec2 describe-volumes --query "Volumes[].VolumeId" --output text
aws ec2 describe-addresses --query "Addresses[].PublicIp" --output text
aws eks list-clusters --query clusters --output text
