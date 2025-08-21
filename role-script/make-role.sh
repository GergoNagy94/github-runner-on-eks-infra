#!/bin/bash
set -e

role_name="terragrunt-execution-role"
account_file="$1"

if [[ -z "$1" ]]; then
    echo "Usage: $0 <accont_file.json>"
    exit 1
fi

#template
account_id=$(jq -r '.account_id' "$account_file")
config=$(sed "s/\${account_id}/$account_id/g" "$account_file")

#extract
trust_policy=$(echo "$config" | jq -c '.policies.trust')
inline_policy=$(echo "$config" | jq -c '.policies.inline')
managed_policies=$(echo "$config" | jq -r '.policies.managed[]')

aws iam get-role --role-name "$role_name" &>/dev/null || \
    aws iam create-role --role-name "$role_name" --assume-role-policy-document "$trust_policy" --tags Key=created_by,Value=script

for policy_arn in $managed_policies; do
    aws iam attach-role-policy --policy-arn "$policy_arn" --role-name "$role_name"
done

aws iam put-role-policy --role-name "$role_name" --policy-name "inline-policy" --policy-document "$inline_policy"