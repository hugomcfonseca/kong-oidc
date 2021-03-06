return {
    no_consumer = true,
    fields = {
        client_id = {type = "string", required = true},
        client_secret = {type = "string", required = true},
        discovery = {
            type = "string",
            required = true,
            default = "https://accounts.google.com/.well-known/openid-configuration"
        },
        introspection_endpoint = {type = "string", required = false},
        redirect_uri_path = {type = "string"},
        scope = {type = "string", required = true, default = "openid profile email"},
        response_type = {type = "string", required = true, default = "code"},
        ssl_verify = {type = "string", required = true, default = "no"},
        token_endpoint_auth_method = {type = "string", required = true, default = "client_secret_post"},
        session_secret = {type = "string", required = false},
        hosted_domain = {type = "string", required = false, default = ""},
        recovery_page_path = {type = "string"},
        filters = {type = "string"}
    }
}
