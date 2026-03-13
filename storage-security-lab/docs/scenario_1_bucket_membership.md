# Scenario 1 – Bucket Membership Access

This scenario demonstrates safe file access in a family-based multi-tenant app.

## Model

- bucket is private
- file path starts with `family_id`
- access is granted through membership in `family_members`

Example object path:

```text
<family_id>/photo1.jpg
```

## Expected behavior
### Allowed

A user can:

+ list files for their family

+ upload files into their family folder

+ read files belonging to their family

### Forbidden

A user cannot:

+ list another family's folder

+ upload into another family's folder

+ read another family's files

### Security idea

The storage policy uses the first path segment as tenant boundary.

Membership is checked through:

+ family_members

+ auth.uid()

### Why this matters

This is the safest pattern for family/team storage in Supabase:

+ private bucket

+ path-based tenant isolation

+ RLS-backed membership check