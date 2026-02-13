const std = @import("std");
const print = std.debug.print;

// internal imports
const comp = @import("utils/comparators.zig");
const verifyer = @import("backend/verifyers.zig");
const lister = @import("backend/lister.zig");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next(); // nome do binario

    if (args.next()) |command| {
        if (comp.equals(command, "pack")) {
            var dir_path: []const u8 = ".";
            var out_name_pfs: []const u8 = "out";

            // verifica se o usuario passou o argumento <dir>
            if (args.next()) |dir_path_input| {
                if (!verifyer.is_directory(dir_path_input)) {
                    print("ERRO: O caminho '{s}' precisa ser um diretorio.\n", .{dir_path_input});
                    return;
                }
                dir_path = dir_path_input;
            }

            // verifica se o usuario passou o argumento <out.pfs>
            if (args.next()) |out_name_pfs_input| {
                if (out_name_pfs_input.len == 0) {
                    print("ERRO: O nome do arquivo.pfs de saida '{s}' não pode ser vazio.\n", .{out_name_pfs_input});
                    return;
                }

                out_name_pfs = out_name_pfs_input;
            }

            // packer.pack(dir_path, out_name_pfs);
            return;
        }

        if (comp.equals(command, "list")) {
            // verifica se o usuátio passou o arquivo.pfs como argumento
            if (args.next()) |file_pfs| {
                if (!std.mem.endsWith(u8, file_pfs, ".pfs")) {
                    print("ERRO: O arquivo '{s}' não é um arquivo .pfs\n", .{file_pfs});
                    return;
                }

                lister.list(file_pfs);
                return;
            }

            print("ERRO: O argumento <file.pfs> não pode estar vazio.\n", .{});
            return;
        }

        if (comp.equals(command, "extract")) {
            var name_pfs: []const u8 = ".";
            var out_dir: []const u8 = ".";

            if (args.next()) |name_pfs_input| {
                if (name_pfs_input.len == 0) {
                    print("ERRO: O nome do arquivo.pfs '{s}' não pode ser vazio.\n", .{name_pfs_input});
                    return;
                }

                if (!std.mem.endsWith(u8, name_pfs_input, ".pfs")) {
                    print("ERRO: O arquivo '{s}' não é um arquivo .pfs\n", .{name_pfs_input});
                    return;
                }
                name_pfs = name_pfs_input;
            }

            if (args.next()) |out_dir_input| {
                if (!verifyer.is_directory(out_dir_input)) {
                    print("ERRO: O caminho '{s}' precisa ser um diretorio.\n", .{out_dir_input});
                    return;
                }

                out_dir = out_dir_input;
            }
            // extracter.extract(name_pfs, out_dir);
            return;
        }

        if (comp.equals_command(command, &.{ "-h", "--help" })) {
            help();
            return;
        }

        if (comp.equals_command(command, &.{ "-v", "--version" })) {
            print("packfs - v0.0.1-dev\n", .{});
        }
    }
}

fn help() void {
    print("Uso: packfs <comando> <flags>\n\n", .{});

    print("Comandos disponíveis\n", .{});
    print("    pack:                 Empacota recursivamente, preserva paths relativos não compacta, não criptografa\n", .{});
    print("    list:                 Lista: path, size, offset (opcional), mtime (se você guardar).\n", .{});
    print("    extract:              Extrai tudo, cria diretórios necessários, protege contra path traversal (tipo `../../`).\n\n", .{});

    print("Comandos Gerais\n", .{});
    print("    -h, --help:           Mostra esse help log.\n", .{});
    print("    -v, --version:        Mostra a versão do packfs\n", .{});
}
