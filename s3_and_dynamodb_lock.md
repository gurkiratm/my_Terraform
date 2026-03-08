## To enable Terraform state locking with DynamoDB, you must configure two things:

1️⃣ AWS resources (S3 + DynamoDB)
2️⃣ Terraform backend configuration

I'll show the complete setup used in real production.

### 1️⃣ AWS Resources Required

Terraform remote state with locking requires:

| Resource |	Purpose |
|---------|---------|
| S3 Bucket |	Store Terraform state file |
| DynamoDB Table |	Store lock record |

### Create S3 Bucket (State Storage)

You can create it using AWS CLI:

```bash
aws s3api create-bucket \
  --bucket my-terraform-state-bucket-vpshere \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
```

Best practice settings:

```bash
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket-vpshere \
  --versioning-configuration Status=Enabled 
```

Enable encryption:

```bash
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket-vpshere \
  --server-side-encryption-configuration '{
  "Rules": [{
    "ApplyServerSideEncryptionByDefault": {
      "SSEAlgorithm": "AES256"
    }
  }]
}'
```
Why versioning is important

If state gets corrupted you can restore previous versions.

### 2️⃣ Create DynamoDB Lock Table

Create table:

```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```


Table structure:

| Attribute |	Type |	Purpose |
|---------|---------|---------|
| LockID	| String |	Unique lock identifier |

Terraform automatically inserts lock rows.

### 3️⃣ Terraform Backend Configuration

Add this in `backend.tf` or inside `terraform {}` block.

```bash
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-vpshere"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Explanation

| Parameter | Meaning |
|---------|---------|
| bucket |	S3 bucket storing state |
| key |	path of state file |
| region |	AWS region |
| dynamodb_table |	table used for locking |
| encrypt |	enable state encryption |

### 4️⃣ Initialize Terraform Backend

After adding backend config run:

```bash
terraform init 
```

Terraform will ask:

```
Do you want to copy existing state to the new backend?
```

Answer:

```
yes
```

Now the state moves to S3.

### 5️⃣ What Happens During terraform apply

Workflow:

```
terraform apply
     │
     ▼
Check DynamoDB table
     │
     ├─ If LockID exists → fail
     │
     └─ If no LockID → create lock
            │
            ▼
        Modify AWS resources
            │
            ▼
        Update state in S3
            │
            ▼
        Delete lock in DynamoDB
```

### 6️⃣ Verify Lock in DynamoDB

While Terraform is running you can check:

```bash
aws dynamodb scan --table-name terraform-locks
```

Example output:

```json
{
  "Items": [
    {
      "LockID": { "S": "dev/terraform.tfstate" }
    }
  ]
}
```

That means lock is active.

### 7️⃣ Required AWS IAM Permissions

Terraform user needs:

S3 permissions

```json
{
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ],
  "Effect": "Allow"
}
```
DynamoDB permissions

```json
{
  "Action": [
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:DeleteItem",
    "dynamodb:DescribeTable"
  ],
  "Effect": "Allow"
}
```

### 8️⃣ Example Terraform Project

```
terraform-project/
│
├── main.tf
├── variables.tf
├── backend.tf
└── provider.tf
```

Example `provider.tf`:

```
provider "aws" {
  region = "us-east-1"
}
```

### 9️⃣ Real Production Best Practice

Most companies create a separate Terraform project just for backend infrastructure.

Example:

```
terraform-bootstrap/
   ├── s3-state-bucket
   └── dynamodb-lock-table
```

Then all other Terraform projects use that backend.

Quick Architecture

```
Terraform CLI
      │
      ▼
DynamoDB (Locking)
      │
      ▼
S3 Bucket (State file)
      │
      ▼
AWS Infrastructure
```

## Clean Up

### 1. First destroy Terraform infrastructure (if any)

If you created resources using Terraform:

```bash 
terraform destroy
```

> Do this before deleting the backend resources (S3 + DynamoDB), otherwise Terraform may fail to read state.

### 2. Delete S3 Bucket

S3 buckets cannot be deleted if they contain objects.

First remove objects:

```bash
aws s3 rm s3://my-terraform-state-bucket-vpshere --recursive
```

verify:

```bash
aws s3 ls s3://my-terraform-state-bucket-vpshere
```

Versioning enabled

If versioning was enabled (recommended for Terraform state):

```bash
aws s3api list-object-versions --bucket my-terraform-state-bucket-vpshere
```
You must delete all versions before deleting bucket.

```bash
aws s3api delete-object --bucket my-terraform-state-bucket-vpshere --key dev/terraform.tfstate --version-id <version-id>
```

Then delete bucket:

```bash
aws s3api delete-bucket --bucket my-terraform-state-bucket-vpshere --region ap-south-1
``` 

### 3. Delete DynamoDB Table

```bash
aws dynamodb delete-table --table-name terraform-locks --region ap-south-1
```

Check deletion status:

```bash
aws dynamodb list-tables --region ap-south-1
aws dynamodb describe-table --table-name terraform-locks --region ap-south-1
```