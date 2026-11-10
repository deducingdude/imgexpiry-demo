#!/usr/bin/env bash
# Push tiny, distinct test images to the imgexpiry-demo ECR repository.
#
#   v1.0.0 .. v1.4.0   -> rule 2 (keep the last 3 v* images): v1.0.0 and v1.1.0 are over the limit
#   build-42-rc1       -> rule 3 (both patterns match, 14 days)
#   build-43           -> only "build-*" matches: falls through to rule 4 (any, 90 days)
#   hotfix-rc3         -> only "*-rc*" matches: falls through to rule 4
#   two untagged       -> rule 1 (untagged, 7 days)
#   scratch            -> leftover tag from creating the untagged images (rule 4)
#
# Push times can't be backdated, so age-based rules will predict dates in the
# future. Only the count rule can have an effect today.
set -euo pipefail

PROFILE=${PROFILE:-imgexpiry}
REGION=${REGION:-us-west-2}
REPO=${REPO:-imgexpiry-demo}

ACCOUNT=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)
REGISTRY="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

aws ecr get-login-password --profile "$PROFILE" --region "$REGION" |
  docker login --username AWS --password-stdin "$REGISTRY" >/dev/null

# push TAG: builds an image with unique content, so each push is a distinct digest.
push() {
  local tag=$1 dir
  dir=$(mktemp -d -p "$WORK" 2>/dev/null || mktemp -d "$WORK/img.XXXXXX")
  echo "$tag $(date +%s%N 2>/dev/null || date +%s) $RANDOM" >"$dir/id"
  printf 'FROM scratch\nCOPY id /id\n' >"$dir/Dockerfile"
  docker build --quiet --provenance=false -t "$REGISTRY/$REPO:$tag" "$dir" >/dev/null
  docker push --quiet "$REGISTRY/$REPO:$tag" >/dev/null
  echo "pushed $REPO:$tag"
  sleep 2  # keep push times distinct so ranking is unambiguous
}

for v in v1.0.0 v1.1.0 v1.2.0 v1.3.0 v1.4.0; do push "$v"; done
for t in build-42-rc1 build-43 hotfix-rc3; do push "$t"; done

# Re-pushing a tag moves it to the new image and leaves the old one untagged.
push scratch
push scratch
push scratch

aws ecr describe-images --profile "$PROFILE" --region "$REGION" --repository-name "$REPO" \
  --query 'sort_by(imageDetails,&imagePushedAt)[].[imageTags[0],imageDigest,imagePushedAt]' --output table
