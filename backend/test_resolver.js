const assert = require('assert');
const { resolveVariables, resolveObject } = require('./src/services/variableResolver.service');

console.log('=== RUNNING VARIABLE RESOLVER UNIT TESTS ===');

// Test 1: Standard key substitution
const text1 = 'Hello {{name}}, welcome to {{service}}!';
const vars1 = [
  { key: 'name', value: 'Alice', enabled: true },
  { key: 'service', value: 'Inspecto', enabled: true },
];
assert.strictEqual(
  resolveVariables(text1, vars1),
  'Hello Alice, welcome to Inspecto!'
);
console.log('✓ Test 1 Passed: Standard variable replacement');

// Test 2: Regex special characters in variable keys (dot, brackets, dollar, plus)
const text2 = 'https://{{api.domain}}/v1/users/{{user[id]}}?token={{auth$secret}}+{{a+b}}';
const vars2 = [
  { key: 'api.domain', value: 'api.example.com', enabled: true },
  { key: 'user[id]', value: '42', enabled: true },
  { key: 'auth$secret', value: 'xyz789', enabled: true },
  { key: 'a+b', value: 'sum_val', enabled: true },
];
assert.strictEqual(
  resolveVariables(text2, vars2),
  'https://api.example.com/v1/users/42?token=xyz789+sum_val'
);
console.log('✓ Test 2 Passed: Special regex characters in keys resolved safely');

// Test 3: Disabled variables must not be replaced
const text3 = 'Token is {{token}}';
const vars3 = [{ key: 'token', value: 'secret', enabled: false }];
assert.strictEqual(resolveVariables(text3, vars3), 'Token is {{token}}');
console.log('✓ Test 3 Passed: Disabled variables ignored');

// Test 4: Object input support (Map/dictionary instead of array)
const text4 = 'Connecting to {{host}}:{{port}}';
const vars4 = { host: 'localhost', port: '8080' };
assert.strictEqual(resolveVariables(text4, vars4), 'Connecting to localhost:8080');
console.log('✓ Test 4 Passed: Object/dictionary variables resolved');

// Test 5: Deep object resolution
const obj = {
  url: '{{baseUrl}}/users',
  headers: {
    Authorization: 'Bearer {{token}}',
    'X-Client': 'Inspecto',
  },
};
const resolvedObj = resolveObject(obj, [
  { key: 'baseUrl', value: 'https://api.test.com', enabled: true },
  { key: 'token', value: 'jwt123', enabled: true },
]);
assert.strictEqual(resolvedObj.url, 'https://api.test.com/users');
assert.strictEqual(resolvedObj.headers.Authorization, 'Bearer jwt123');
assert.strictEqual(resolvedObj.headers['X-Client'], 'Inspecto');
console.log('✓ Test 5 Passed: Deep object resolution');

// Test 6: Invalid/null/empty handling
assert.strictEqual(resolveVariables(null, vars1), null);
assert.strictEqual(resolveVariables(undefined, vars1), undefined);
assert.strictEqual(resolveVariables('no vars', null), 'no vars');
assert.strictEqual(resolveVariables('no vars', undefined), 'no vars');
assert.strictEqual(resolveVariables('no vars', []), 'no vars');
console.log('✓ Test 6 Passed: Null/undefined safety');

console.log('=== ALL VARIABLE RESOLVER TESTS PASSED (6/6) ===');
