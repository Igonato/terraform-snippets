# Terraform Snippets

Collection of tested Terraform recipes.


## S3 Bucket for web

[s3_bucket_web_and_credentials][1] - create an S3 bucket and output a set of
credentials for writing. Can be used to serve a static website or static files
for a Django/Flask website.


## Route 53 zone

[route53_zone][2] - create a zone for a given domain and output name servers.


## ACM certificate

[acm_cetificate][2] - create and validate a certificate for a given domain.
Slow, can take up to 5 minutes.


[1]: s3_bucket_web_and_credentials/s3_bucket_web_and_credentials.tf
[2]: route53_zone/route53_zone.tf
[3]: acm_cetificate/acm_cetificate.tf

