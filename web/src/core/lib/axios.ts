import axios from 'axios';

import { API_BASE_URL } from '../constants/api';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10_000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor — agregar token Firebase
apiClient.interceptors.request.use(async (config) => {
  // TODO(auth): obtener token Firebase del store y agregarlo
  // const token = store.getState().auth.token;
  // if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor — manejo centralizado de errores
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // TODO(auth): redirigir a login
    }
    return Promise.reject(error);
  },
);
