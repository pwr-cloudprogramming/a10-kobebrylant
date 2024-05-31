const awsExports = {
    Auth: {
        Cognito: {
            region: process.env.VUE_APP_COGNITO_REGION || 'us-east-1',
            userPoolId: process.env.VUE_APP_COGNITO_USER_POOL_ID || 'us-east-1_abc123',
            userPoolClientId: process.env.VUE_APP_COGNITO_CLIENT_ID || 'abc123',
        }
    }
}
export default awsExports;