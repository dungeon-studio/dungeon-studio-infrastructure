<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Connect Grafana to Cloud Monitoring

Set the service account key on the `GCP Cloud Monitoring` data source when it
is first created, when a change recreates it, and after rotating the key.
Terraform leaves the key out because it would persist in state that pull
request plans can read. Routine applies leave the key in place.

## Prerequisites

- `just bootstrap` and the infrastructure layer both applied.
- `gcloud` and `jq` installed, with `gcloud` signed in as an identity that can
  read the `grafana-gcp-reader-key` secret. The deployers can't.
- [gcx](https://github.com/grafana/gcx) installed and signed in to the stack
  as a `dungeonstudio` context:

  ```sh
  gcx login dungeonstudio --server https://dungeonstudio.grafana.net --oauth
  ```

## Set the key

```sh
just configure-grafana-gcp
```

It sets every data source that authenticates as `grafana-gcp-reader`. To set
only some, pass their identifiers:
`just configure-grafana-gcp gcp-cloud-monitoring`. Set `GCX_CONTEXT` if your
context has another name.

Confirm it authenticates: **Connections → Data sources → GCP Cloud
Monitoring → Save & test**.

## Query a product's metrics

A product's projects answer only after that product grants
`grafana-gcp-reader` `roles/monitoring.viewer`. To check a product's container
startup latency, pick `GCP Cloud Monitoring` in **Explore**, choose the
product's project, and query the metric
`run.googleapis.com/container/startup_latencies`.

## Rotate the key

1. Replace the key in bootstrap. It prompts for the billing account and the
   same tokens as `just bootstrap`; [Create the Grafana Cloud bootstrap
   token](create-grafana-cloud-bootstrap-token.md) covers the Grafana one.

   ```sh
   terraform -chdir=terraform/bootstrap apply \
     -replace=google_service_account_key.grafana_gcp_reader
   ```

2. Run `just configure-grafana-gcp`. Until you do, the data source keeps the
   deleted key and every query fails.
