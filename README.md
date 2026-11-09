# imgexpiry-demo

Throwaway AWS sandbox for [imgexpiry](../imgexpiry): an ECR repository with the
same lifecycle policy as imgexpiry's `fixtures/lifecycle-policy.json`, so the
predictor can be compared with AWS's lifecycle preview.

Creates, in account 340754910639 / us-west-2:

- ECR repository `imgexpiry-demo` (`force_delete`, so destroy works with images in it)
- its lifecycle policy (`lifecycle-policy.json`)

Keep `lifecycle-policy.json` in sync with imgexpiry's fixture if you change either.

## Use

```
aws sso login --profile imgexpiry
tofu init
tofu plan
tofu apply
```

The `imgexpiry-ecr` permission set must allow the ECR actions OpenTofu calls
(tagging, listing tags, deleting lifecycle policies); `ecr:*` is fine for this sandbox.

Tear down when finished:

```
tofu destroy
```

State is local and ignored by git.
