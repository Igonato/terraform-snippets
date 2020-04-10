# Terraform Snippets

Collection of tested Terraform recipes.


## S3 Bucket for web

[s3_bucket_web_and_credentials][1] - create an S3 bucket and output a set of
credentials for writing. Can be used to serve a static website or static files
for a Django/Flask website.

```sh
cd s3_bucket_web_and_credentials
terraform init
terraform apply
```


## Route 53 zone

[route53_zone][2] - create a zone for a given domain and output name servers.

```sh
cd route53_zone
export TF_VAR_domain_name=example.com
terraform init
terraform apply
```


## ACM certificate

[acm_cetificate][3] - create and validate a certificate for a given domain.

```sh
cd acm_cetificate
export TF_VAR_domain_name=example.com
terraform init
terraform apply
```


## CloudFront with s3 for web

[cloudfront_s3_web][4] - Bucket and ACM configs from above put together with a
CloudFront distribution for static website/files hosting.

```sh
cd cloudfront_s3_web
export TF_VAR_domain_name=example.com
terraform init
terraform apply
```


[1]: s3_bucket_web_and_credentials/s3_bucket_web_and_credentials.tf
[2]: route53_zone/route53_zone.tf
[3]: acm_cetificate/acm_cetificate.tf
[4]: cloudfront_s3_web/cloudfront_s3_web.tf
