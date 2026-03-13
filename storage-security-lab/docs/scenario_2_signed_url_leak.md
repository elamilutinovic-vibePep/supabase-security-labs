# Scenario 2 – Signed URL Leak

This scenario demonstrates a common security mistake:

an Edge Function generates signed URLs using `service_role` without validating ownership.

## Problem

The bucket itself may be private and storage policies may be correct.

However, a user-facing Edge Function can still leak files if it does this:

```ts
createClient(url, serviceRoleKey)
```

and then signs a path provided by the caller.

## Result

User A can request a signed URL for:

```text
<family_b_id>/photo.jpg
```

and receive valid access to another family's file.

## Correct fix

The Edge Function must use:

+ anon key

+ forwarded user JWT

This keeps storage policy enforcement active.

## Key point

A private bucket is not enough if your Edge Function bypasses the policy layer.

The real rule is:

+ private bucket

+ correct storage policy

+ no privileged signed URL generator for user-facing access