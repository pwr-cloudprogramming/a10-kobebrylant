const awsconfig = {
  Auth: {
    identityPoolId: "${identity_pool_id}",
    region: "us-east-1",
    userPoolId: "${user_pool_id}",
    userPoolWebClientId: "${user_pool_client_id}"
  }
};

export default awsconfig;
