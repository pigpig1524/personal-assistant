# [LOTUS-IPA] Deployment Documentation
First of all, here are some important notes:
- The bash scripts and commands provided are designed for Linux-based systems.
- Since we are building a mobile application, this documentation focuses solely on server-side deployment.

## ⚡ TL;DR
Backend server is deployed to `Cloud Run`, a fully managed compute platform on `Google Cloud Platform (GCP)`

Before proceeding, ensure that your local environment is properly set up — this includes the gcloud CLI, necessary permissions, and project configuration.


*If you want to deploy by yourself, let's begin...*

## Prepare your GCP 
First, head to the [GCP Console](https://console.cloud.google.com/) and sign in.

Make sure you have an active GCP subscription (the Free Trial works too)

### Create a project
If you already have a GCP project, great — you can skip this step.

Otherwise, follow [Google's official guide](https://developers.google.com/workspace/guides/create-project) to create a new project.

> 📝 All subsequent actions and resources will be associated with the GCP project you've created

### Enable related services, APIs
Find services and enable the following services:
- Cloud Run
- Artifact Registry

### Prepare a service account
Navigate to `Service Account` and create service account. Perform the following steps:
- Give it a name, `cloud-run` for example
- Assign some necessary permission:
    - Artifact Registry Administrator
    - Cloud Build Service Account
    - Cloud Run Admin
    - Service Account User
- Grant access to your email account: The webUI is very clear, or follow [official guide here](https://cloud.google.com/iam/docs/manage-access-service-accounts)

## CLI setup
### Setup `gcloud` CLI
Follow the [Google official document](https://cloud.google.com/sdk/docs/install)

### Authen docker when interact with Artifact Registry
Follow the guidance in **"Standalone credential helper"** section, [here](https://cloud.google.com/artifact-registry/docs/docker/authentication#standalone-helper)

*Note:* authen the server locations `asia-northeast1` for current configuration