const axios = require('axios');
const qs = require('qs');
const FormData = require('form-data');
const { resolveVariables, resolveObject } = require('./variableResolver.service');
const ExecutionLog = require('../models/ExecutionLog');

const executeRequest = async (requestData, environment) => {
  let { method, url, headers, params, body, bodyType, bodySubType, authType, authDetails } = requestData;

  // 1. Resolve Variables (if env provided)
  if (environment && environment.variables) {
    url = resolveVariables(url, environment.variables);
    headers = resolveObject(headers, environment.variables);
    body = resolveObject(body, environment.variables);
    params = resolveObject(params, environment.variables);
    authDetails = resolveObject(authDetails, environment.variables);
  }

  // 2. Prepare Axios Config
  const headerObj = headers || {};
  const paramObj = params || {};

  // Handle Authentication
  if (authType && authType !== 'none') {
    if (authType === 'bearer' && authDetails?.token) {
      headerObj['Authorization'] = `Bearer ${authDetails.token}`;
    } else if (authType === 'basic' && authDetails?.username) {
      const credentials = `${authDetails.username}:${authDetails.password || ''}`;
      const encoded = Buffer.from(credentials).toString('base64');
      headerObj['Authorization'] = `Basic ${encoded}`;
    } else if (authType === 'apiKey' && authDetails?.key && authDetails?.value) {
      if (authDetails.addTo === 'query') {
        paramObj[authDetails.key] = authDetails.value;
      } else {
        headerObj[authDetails.key] = authDetails.value;
      }
    }
  }

  // Handle Body and Content-Type
  let data = body;
  if (bodyType !== 'none' && body) {
    if (bodyType === 'json' || bodyType === 'graphql') {
      headerObj['Content-Type'] = 'application/json';
      try { data = typeof body === 'string' ? JSON.parse(body) : body; } catch(e) {}
    } else if (bodyType === 'x-www-form-urlencoded') {
      headerObj['Content-Type'] = 'application/x-www-form-urlencoded';
      try { 
        const parsedBody = typeof body === 'string' ? JSON.parse(body) : body;
        data = qs.stringify(parsedBody); 
      } catch(e) { data = body; }
    } else if (bodyType === 'raw') {
      const mimeTypes = {
        'text': 'text/plain',
        'json': 'application/json',
        'javascript': 'application/javascript',
        'html': 'text/html',
        'xml': 'application/xml'
      };
      headerObj['Content-Type'] = mimeTypes[bodySubType] || 'text/plain';
    }
  }

  const config = {
    method: method.toLowerCase(),
    url: url,
    headers: headerObj,
    params: paramObj,
    data: bodyType !== 'none' ? data : undefined,
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