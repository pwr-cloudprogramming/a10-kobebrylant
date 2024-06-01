const awsExports = {
    Auth: {
        Cognito: {
            userPoolId: process.env.VUE_APP_COGNITO_USER_POOL_ID,
            userPoolClientId: process.env.VUE_APP_COGNITO_CLIENT_ID
        }
    }
}


export default awsExports;