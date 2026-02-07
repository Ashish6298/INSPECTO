/**
 * Replaces {{key}} in a string with values from the environment variables.
 */
const resolveVariables = (inputString, variables) => {
  if (!inputString || typeof inputString !== 'string') return inputString;
  
  let resolvedString = inputString;
  variables.forEach(variable => {
    if (variable.enabled) {
      const regex = new RegExp(`{{${variable.key}}}`, 'g');
      resolvedString = resolvedString.replace(regex, variable.value);
    }
  });
  return resolvedString;
};

/**
 * Deeply resolves variables in an object (headers, body, etc).
 */
const resolveObject = (obj, variables) => {
  const str = JSON.stringify(obj);
  const resolvedStr = resolveVariables(str, variables);
  return JSON.parse(resolvedStr);
};

module.exports = { resolveVariables, resolveObject };