{
  lib,
  pkgs,
  mylib,
  ...
}:
let
  python3 = mylib.py pkgs;
  mlflow = python3.pkgs.buildPythonPackage rec {
    pname = "mlflow";
    version = "3.9.0";
    format = "wheel";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      format = "wheel";
      python = "py3";
      hash = "sha256-KA+UhU5ezkL8VTgYCydmYcYtv7LISKmOiHPniRU3msY=";
    };

    pythonRelaxDeps = [
      "cachetools"
      "cryptography"
      "gunicorn"
      "importlib-metadata"
      "packaging"
      "protobuf"
      "pyarrow"
    ];

    dependencies = with python3.pkgs; [
      alembic
      cachetools
      click
      cloudpickle
      cryptography
      databricks-sdk
      docker
      fastapi
      flask
      flask-cors
      gitpython
      graphene
      gunicorn
      huey
      importlib-metadata
      matplotlib
      numpy
      opentelemetry-api
      opentelemetry-proto
      opentelemetry-sdk
      packaging
      pandas
      protobuf
      pyarrow
      pydantic
      python-dotenv
      pyyaml
      requests
      scikit-learn
      scipy
      skops
      sqlalchemy
      sqlparse
      typing-extensions
      uvicorn

      # genai optional dependencies
      aiohttp
      boto3
      litellm
      slowapi
      tiktoken
      watchfiles
    ];

    pythonImportsCheck = [ "mlflow" ];

    doCheck = false;

    meta = {
      description = "Open source platform for the machine learning lifecycle";
      mainProgram = "mlflow";
      homepage = "https://github.com/mlflow/mlflow";
      changelog = "https://github.com/mlflow/mlflow/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ tbenst ];
    };
  };
  pythonWithMlflow = python3.withPackages (_: [ mlflow ]);
in
pythonWithMlflow
