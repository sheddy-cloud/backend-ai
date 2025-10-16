module.exports = {
  apps: [
    {
      name: 'napasa-ai-backend',
      script: 'src/server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      error_file: './logs/ai-backend-err.log',
      out_file: './logs/ai-backend-out.log',
      log_file: './logs/ai-backend-combined.log',
      time: true,
      restart_delay: 4000
    },
    {
      name: 'napasa-ml-service',
      script: 'ml_service/main.py',
      interpreter: 'ml_service/venv/bin/python',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      env: {
        NODE_ENV: 'production',
        PORT: 8000,
        HOST: '0.0.0.0'
      },
      error_file: './ml_service/logs/ml-service-err.log',
      out_file: './ml_service/logs/ml-service-out.log',
      log_file: './ml_service/logs/ml-service-combined.log',
      time: true,
      restart_delay: 4000,
      min_uptime: '10s',
      max_restarts: 5
    }
  ]
};







