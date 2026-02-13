const std = @import("std");
const print = std.debug.print;

// internal imports
const comp = @import("utils/comparators.zig");
const verifyer = @import("backend/verifyers.zig");

const lister = @import("backend/lister.zig");
const packer = @import("backend/packer.zig");
const extracter = @import("backend/extracter.zig");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next(); // nome do binario

    if (args.next()) |command| {
        if (comp.equals(command, "pack")) {
            var dir_path: []const u8 = ".";
            var out_name_pfs: []const u8 = "out";
            var recursive: bool = false;

            while (args.next()) |arg| {
                if (comp.equals_command(arg, &.{ "-r", "--recursive" })) {
                    recursive = true;
                } else if (dir_path.ptr == @as([]const u8, ".").ptr) {
                    // Primeiro argumento não-flag = dir_path
                    if (!verifyer.is_directory(arg)) {
                        print("ERRO: O caminho '{s}' precisa ser um diretorio.\n", .{arg});
                        return;
                    }
                    dir_path = arg;
                } else if (out_name_pfs.ptr == @as([]const u8, "out").ptr) {
                    // Segundo argumento não-flag = out_name_pfs
                    if (arg.len == 0) {
                        print("ERRO: O nome do arquivo.pfs de saida não pode ser vazio.\n", .{});
                        return;
                    }
                    out_name_pfs = arg;
                } else {
                    print("ERRO: Argumento inesperado '{s}'.\n", .{arg});
                    return;
                }
            }

            try packer.pack(dir_path, out_name_pfs, recursive);
            return;
        }

        if (comp.equals(command, "list")) {
            // verifica se o usuátio passou o arquivo.pfs como argumento
            if (args.next()) |file_pfs| {
                if (!std.mem.endsWith(u8, file_pfs, ".pfs")) {
                    print("ERRO: O arquivo '{s}' não é um arquivo .pfs\n", .{file_pfs});
                    return;
                }

                try lister.list(file_pfs);
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
                out_dir = out_dir_input;

                try verifyer.ensure_directory(out_dir);
            }

            try extracter.extract(name_pfs, out_dir);
            return;
        }

        if (comp.equals_command(command, &.{ "-h", "--help" })) {
            help();
            return;
        }

        if (comp.equals_command(command, &.{ "-v", "--version" })) {
            print("packfs - v0.2.1-dev\n", .{});
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
