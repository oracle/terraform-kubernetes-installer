# CI/CD 

Our builds are set to automatically build any changes to any branches including master branch. The 
.gitlab-ci.yml file sets up it's environment based on environment variables that are defined in the 
project settings. The variables that must be set are:
* TF_VAR_fingerprint
* TF_VAR_user_ocid
* TF_VAR_private_key
* TF_VAR_region
* TF_VAR_tenancy_ocid
* TF_VAR_compartment_ocid

## Manual testing
To manually test you would need to:
* Install gitlab-runner
* Define the above variables
* Run the gitlab-runner command:

```
gitlab-runner exec docker deploy_from_scratch --env "SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY" \
  --env http_proxy=$http_proxy --env https_proxy=$https_proxy --env no_proxy=$no_proxy \
  --env ALL_PROXY=$ALL_PROXY --env "TF_VAR_fingerprint=$TF_VAR_fingerprint" \
  --env "TF_VAR_user_ocid=$TF_VAR_user_ocid" --env "TF_VAR_private_key=$TF_VAR_private_key" \
  --env "TF_VAR_region=$TF_VAR_region" --env "TF_VAR_tenancy_ocid=$TF_VAR_tenancy_ocid" \
  --env "TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid" --docker-pull-policy if-not-present
```
The --docker-pull-policy "if-not-present" allows you to use local images which you can modify freely. The Dockerfile 
in this repo defines an image you could build.
