import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 30 },  // 10 usuários em 30s
    { duration: '30', target: 500 },   // 50 usuários por 1 min
    { duration: '30s', target: 0 },   // Redução gradual para 0
  ],
};

export default function () {
  let res = http.get('https://clubebetta.thinklife.com.br/banners', { timeout: '1000s' });

  check(res, {
    'status é 200': (r) => r.status === 200,
    'tempo de resposta < 500ms': (r) => r.timings.duration < 5200,
  });
  sleep(1);
}
