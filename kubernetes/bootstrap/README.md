# Private RDS bootstrap

Apply Terraform before this directory. Terraform creates the RDS endpoint and
application credentials in SSM Parameter Store. The application workflow then
replaces the `REPLACE_WITH_*_IRSA_ROLE_ARN` annotations using Terraform outputs.

Prerequisites:

1. The GitHub Actions AWS role must be authorized to administer the EKS cluster.
2. The RDS security group must allow TCP/5432 from EKS workloads.
3. External Secrets Operator must be installed before applying any `SecretStore`
   or `ExternalSecret` resource. The application workflow installs it.
4. The bootstrap IAM role may read the RDS master credential. Tenant roles may
   read only their own parameters plus the shared config-db password.

The bootstrap Job is safe to rerun: it creates missing roles/databases and
applies only migrations that are absent from `schema_migrations`. It does not
run the legacy `init_*.sql` seed scripts, because those scripts drop tables.
