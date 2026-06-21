# Startup Pitch Room (创业路演) — 在 openagents-stack 上快速跑 demo

## 这个 Demo 是干什么的

多角色扮演，模拟创业路演场景。

## 前置条件

- openagents-stack 已安装
- docker 可用
- Python 环境可用

## 5 步跑起 创业路演

### 1. 启动 openagents-stack backend
```bash
openagents-stack --start
```

### 2. 启动 SDK network
```bash
cd ~/openagents-stack/examples/demos/pitch_room
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
cd ~/openagents-stack/examples/demos/pitch_room
./run.sh
```

## 关闭
```bash
openagents-stack --stop
```
