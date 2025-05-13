export function sanitizeJsonString(raw: string): string {
  return raw
    .trim()
    .replace(/^```(?:json)?\s*/i, '')  // Remove leading ``` or ```json
    .replace(/```$/, '')               // Remove trailing ```
    .trim();
}
