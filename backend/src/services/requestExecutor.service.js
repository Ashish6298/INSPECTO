const axios = require('axios');
const { resolveVariables, resolveObject } = require('./variableResolver.service');
const ExecutionLog = require('../models/ExecutionLog');

const executeRequest = async (requestData, environment) => {
  let { method, url, headers, params, body } = requestData;

  // 1. Resolve Variables (if env provided)
  if (environment && environment.variables) {
    url = resolveVariables(url, environment.variables);
    headers = resolveObject(headers, environment.variables);
    body = resolveObject(body, environment.variables);
    params = resolveObject(params, environment.variables);
  }

  // 2. Prepare Axios Config
  // Convert array of headers/params to object format
  const headerObj = {};
  if (headers) headers.forEach(h => { if(h.enabled) headerObj[h.key] = h.value; });

  const paramObj = {};
  if (params) params.forEach(p => { if(p.enabled) paramObj[p.key] = p.value; });

  const config = {
    method: method.toLowerCase(),
    url: url,
    headers: headerObj,
    params: paramObj,
    data: body && body.type !== 'none' ? body.content : undefined,
    validateStatus: () => true, // Don't throw error on 4xx/5xx
  };

  const startTime = Date.now();

  try {
    // 3. Execute Request
    const response = await axios(config);
    const endTime = Date.now();
    const duration = endTime - startTime;

    // 4. Log Execution
    await ExecutionLog.create({
      requestName: requestData.name || 'Ad-hoc Request',
      method,
      url,
      statusCode: response.status,
      duration,
      responseSize: JSON.stringify(response.data).length,
      success: response.status < 400
    });

    // 5. Return Structured Response
    return {
      status: response.status,
      statusText: response.statusText,
      headers: response.headers,
      data: response.data,
      duration: duration,
      size: JSON.stringify(response.data).length
    };

  } catch (error) {
    const endTime = Date.now();
    return {
      error: true,
      message: error.message,
      duration: endTime - startTime,
      details: error.response ? error.response.data : null
    };
  }
};

module.exports = { executeRequest };