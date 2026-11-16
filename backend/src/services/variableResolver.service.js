/**
 * Replaces {{key}} in a string with values from the environment variables.
 */
const resolveVariables = (inputString, variables) => {
  if (!inputString || typeof inputString !== 'string') return inputString;
  if (!variables) return inputString;

  let varList = [];
  if (Array.isArray(variables)) {
    varList = variables;
  } else if (typeof variables === 'object') {
    varList = Object.entries(variables).map(([key, value]) => ({
      key,
      value: String(value),
      enabled: true,
    }));
  }

  let resolvedString = inputString;
  varList.forEach((variable) => {
    if (variable && variable.enabled !== false && variable.key) {
      const escapedKey = variable.key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(`{{${escapedKey}}}`, 'g');
      const val =
        variable.value !== undefined && variable.value !== null
          ? String(variable.value)
          : '';
      resolvedString = resolvedString.replace(regex, val);
    }
  });
  return resolvedString;
};

/**
 * Deeply resolves variables in an object (headers, body, etc).
 */
const resolveObject = (obj, variables) => {
  if (!obj) return obj;
  try {
    const str = JSON.stringify(obj);
    const resolvedStr = resolveVariables(str, variables);
    return JSON.parse(resolvedStr);
  } catch (e) {
    return obj; // Return original if resolution fails (e.g., circular ref)
  }
};

module.exports = { resolveVariables, resolveObject };
