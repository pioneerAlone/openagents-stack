# Research Team (研究团队) — 在 openagents-stack 上快速跑 demo

## 这个 Demo 是干什么的

多人研究团队协作，router pattern。

## 前置条件

- openagents-stack 已安装
- docker 可用
- Python 环境可用

## 5 步跑起 研究团队

### 1. 启动 openagents-stack backend
```bash
openagents-stack --start
```

### 2. 启动 SDK network
```bash
cd ~/openagents-stack/examples/demos/research_team
openagents network start .
```

### 3. 启动 agent
```bash
openagents agent start agents/<agent-name>.yaml
```

### 4. 启动 Studio
```bash
openagents studio -s
```

### 5. 在 Studio 里使用
- 浏览器打开 http://localhost:8050
- 查看 messaging/wiki/forum 等 mod

## 一键跑
```bash
cd ~/openagents-stack/examples/demos/research_team
./run.sh
```

## 关闭
```bash
openagents-stack --stop
```
