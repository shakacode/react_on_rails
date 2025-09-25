import React from 'react';

import { gql, useQuery } from '@apollo/client';

const GET_FIRST_USER = gql`
  query FirstUser {
    user(id: 1) {
      name
      email
    }
  }
`;

const ApolloGraphQL = () => {
  const { data, error, loading } = useQuery(GET_FIRST_USER);
  if (error) {
    throw error;
  }
  if (loading) {
    return <div>Loading...</div>;
  }
  const { name, email } = data.user;
  return (
    <p>
      <b>{name}: </b>
      {email}
    </p>
  );
};

export default ApolloGraphQL;
