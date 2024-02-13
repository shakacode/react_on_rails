import { gql } from '@apollo/client';

export const UPDATE_USER_MUTATION = gql`
  mutation updateUser($userId: ID!, $newName: String!) {
    updateUser(input: { userId: $userId, newName: $newName }) {
      user {
        id
        name
        email
      }
    }
  }
`;
