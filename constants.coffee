constants =
  api_key: process.env.FULCRUM_API_KEY                          # The API Key for the dispatcher.  Will be used for authentication
  form_id: process.env.FULCRUM_FORM_ID                          # The ID of the Fulcrum app used to store appointments.
  technician_role_id: process.env.FULCRUM_TECHNICIAN_ROLE_ID    # The ID of the role assigned to technicians
  dispatcher_role_id: process.env.FULCRUM_DISPATCHER_ROLE_ID    # The ID of the role assigned to dispatchers
  api_url: process.env.FULCRUM_API_URL                          # The URL for the Fulcrum API. Default = 'https://web.fulcrumapp.com/api/v2/'

module.exports = constants