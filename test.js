import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 },  // 10 usuários em 30s
    { duration: '1m', target: 50 },   // 50 usuários por 1 min
    { duration: '30s', target: 0 },   // Redução gradual para 0
  ],
};

export default function () {
  let res = http.get('http://10.2.1.125:32000?cep=20521100', { timeout: '1000s' });

  check(res, {
    'status é 200': (r) => r.status === 200,
    'tempo de resposta < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
