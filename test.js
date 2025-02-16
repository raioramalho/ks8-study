import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 110, // Número de usuários virtuais
  duration: '30s', // Tempo do teste
};

export default function () {
  http.get('http://10.2.1.125:32000/'); // URL alvo do teste
  sleep(1);
}
