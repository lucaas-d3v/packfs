## Instalação

### Manual
Compile
```bash
zig build -Doptimize=ReleaseFast
```

O binário será gerado em:

```text
zig-out/bin/packfs
```

Você pode copiá-lo para um diretório no seu `PATH`.

### Via `install.sh`

Dê permissão
```bash
sudo chmod +x install.sh
```

Rode
```bash
./install.sh
```

---

## Filosofia

> Faça uma coisa.
> Faça bem.
> Saia.

O packfs segue a filosofia de ferramentas Unix:

* simples
* previsíveis
* fáceis de compor