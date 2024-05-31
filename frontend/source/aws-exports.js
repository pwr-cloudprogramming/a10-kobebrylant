const awsExports = {
    Auth: {
        Cognito: {
            region: process.env.VUE_APP_COGNITO_REGION ,
            userPoolId: process.env.VUE_APP_COGNITO_USER_POOL_ID ,
            userPoolClientId: process.env.VUE_APP_COGNITO_CLIENT_ID
        }
    }
}
export default awsExports;