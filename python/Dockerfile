FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./

# Generate proto files during build
RUN echo 'syntax = "proto3";\n\
package chatapp;\n\
\n\
service MessageService {\n\
  rpc SendMessage (MessageRequest) returns (MessageResponse);\n\
}\n\
\n\
message MessageRequest {\n\
  string username = 1;\n\
  string roomid = 2;\n\
  string message = 3;\n\
}\n\
\n\
message MessageResponse {\n\
  string status = 1;\n\
}' > chatapp.proto && \
    python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. chatapp.proto

EXPOSE 8091 50051

# CMD removed - will be specified in Kubernetes deployment
