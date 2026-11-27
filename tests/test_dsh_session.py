"""Exercise the real DSH tool loop using a local protocol fixture."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from tempfile import TemporaryDirectory
import json
import os
import subprocess
import threading

root = Path(__file__).resolve().parents[1]
requests = []
error = []

class Server(BaseHTTPRequestHandler):
    def do_POST(self):
        incoming = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        requests.append(incoming)
        names = {tool["function"]["name"] for tool in incoming.get("tools", [])}
        if not names:
            self.reply({"role": "assistant", "content": "Yizhi fixture"}, "stop")
            return
        if "yz_save_draft" not in names:
            error.append("yizhi tools missing")
        delta = {"role": "assistant"}
        if len(requests) == 1:
            delta["tool_calls"] = [{
                "index": 0, "id": "call_yizhi_1", "type": "function",
                "function": {"name": "yz_save_draft", "arguments": json.dumps({"ticket": 1, "draft": "fixture diagnosis"})},
            }]
            reason = "tool_calls"
        else:
            if not any(message.get("role") == "tool" and '"ok":true' in str(message.get("content")) for message in incoming["messages"]):
                error.append("missing successful tool result")
            delta["content"] = "YIZHI_TOOL_OK"
            reason = "stop"
        self.reply(delta, reason)
    def reply(self, delta, reason):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.end_headers()
        for payload, finish in [(delta, None), ({}, reason)]:
            chunk = {"id": f"fixture_{len(requests)}", "object": "chat.completion.chunk", "created": 1, "model": "fixture",
                "choices": [{"index": 0, "delta": payload, "finish_reason": finish}]}
            self.wfile.write(f"data: {json.dumps(chunk)}\n\n".encode())
        self.wfile.write(b"data: [DONE]\n\n")
    def log_message(self, *_):
        pass

with TemporaryDirectory() as directory, ThreadingHTTPServer(("127.0.0.1", 0), Server) as server:
    job = threading.Thread(target=server.serve_forever, daemon=True)
    job.start()
    try:
        data = Path(directory)
        env = {**os.environ, "DSH_HOME": str(data / "dsh"), "YIZHI_TEST_KEY": "fixture"}
        script = "/Applications/YZ.app/Contents/Resources/workbench.py"
        cli = ["python3", script, "--state", str(data / "db")]
        subprocess.run(cli + ["import-json", "demo", "example/demo", str(root / "tests/blender-issue.json")], check=True)
        patch = [
            {"id": "agent-default-model", "config": {"provider": "fixture", "model": "fixture"}},
            {"id": "llm-pi-ai", "config": {"providers": {"fixture": {
                "displayName": "Fixture", "apiKeyEnv": "YIZHI_TEST_KEY", "api": "openai-completions",
                "baseURL": f"http://127.0.0.1:{server.server_port}/v1", "models": [{"id": "fixture", "contextWindow": 64000}],
            }}}},
            {"insert": [{"id": "yizhi-workbench", "name": (root / "dsh-plugin/index.mjs").as_uri(),
                         "config": {"stateDir": str(data / "db")}}]},
        ]
        config = data / "test.patch.yml"
        config.write_text(json.dumps(patch))
        result = subprocess.run(["dsh", "--profile", "headless", "--patch", str(config), "Save a draft in YZ ticket 1 using the installed tool."], env=env, cwd=data, timeout=45, capture_output=True, text=True)
        assert result.returncode == 0, result.stderr[-5000:] + result.stdout[-1000:]
        assert "YIZHI_TOOL_OK" in result.stdout and len(requests) >= 2 and not error, (result.stdout, error, result.stderr[-9000:], [[t["function"]["name"] for t in r.get("tools", [])] for r in requests], [m for r in requests for m in r["messages"] if m.get("role")=="tool"])
        ticket = json.loads(subprocess.check_output(cli + ["show", "1"]))
        assert ticket["status"] == "draft" and ticket["draft"] == "fixture diagnosis"
        assert ticket["activity"][-1]["action"] == "draft_from_dsh_session"
        print("DSH tool loop saved a verified draft in the local ticket ledger")
    finally:
        server.shutdown()
