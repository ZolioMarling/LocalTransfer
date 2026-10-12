const std = @import("std");
const class = @import("class.zig");


const ranges: [256]class.Range = blk: {
    @setEvalBranchQuota(20000);
    var table: [256]class.Range = undefined;
    var i: usize = 0;
    for (0 .. 256) |byte| {
        const start = i;
        while (i < dictionary.len and dictionary[i].chinese[0] == byte) i = i + 1;
        table[byte] = .{ .start = start, .end = i };
    }
    break :blk table;
};


pub fn ago_bucket(allocator: std.mem.Allocator, lang: class.Language, label: []const u8, weekday: []const u8) ![]u8 {
    return switch (lang) {
        .chinese => std.fmt.allocPrint(allocator, "{s}（{s}）", .{ label, weekday }),
        .english, .portuguese => std.fmt.allocPrint(allocator, "{s} ({s})", .{ label, weekday })
    };
}


pub fn ago_long(allocator: std.mem.Allocator, lang: class.Language, unit: class.LongUnit, count: i32, weekday: []const u8) ![]u8 {
    return switch (lang) {
        .chinese => switch (unit) {
            .months => std.fmt.allocPrint(allocator, "{d} 个月前（{s}）", .{ count, weekday }),
            .years => std.fmt.allocPrint(allocator, "{d} 年前（{s}）", .{ count, weekday })
        },
        .english => switch (unit) {
            .months => std.fmt.allocPrint(allocator, "{d} months ago ({s})", .{ count, weekday }),
            .years => std.fmt.allocPrint(allocator, "{d} years ago ({s})", .{ count, weekday })
        },
        .portuguese => switch (unit) {
            .months => std.fmt.allocPrint(allocator, "há {d} meses ({s})", .{ count, weekday }),
            .years => std.fmt.allocPrint(allocator, "há {d} anos ({s})", .{ count, weekday })
        }
    };
}


fn translation(entry: class.Text, lang: class.Language) []const u8 {
    return switch (lang) {
        .chinese => entry.chinese,
        .english => entry.english,
        .portuguese => entry.portuguese
    };
}


pub fn text(lang: class.Language, source: []const u8) []const u8 {
    if (lang == .chinese) return source;
    for (dictionary) |entry| if (std.mem.eql(u8, entry.chinese, source)) return translation(entry, lang);
    return source;
}


pub fn is_text_asset(path: []const u8) bool {
    return std.mem.endsWith(u8, path, ".html")
           or
           std.mem.endsWith(u8, path, ".js")
           or
           std.mem.endsWith(u8, path, ".css");
}


pub fn translate(allocator: std.mem.Allocator, lang: class.Language, source: []const u8) ![]const u8 {
    if (lang == .chinese) return source;

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    var start: usize = 0;
    var i: usize = 0;
    var replaced = false;
    while (i < source.len) {
        const entry = match(source, i) orelse {
            i = i + 1;
            continue;
        };
        try out.appendSlice(allocator, source[start .. i]);
        try out.appendSlice(allocator, translation(entry, lang));
        i = i + entry.chinese.len;
        start = i;
        replaced = true;
    }
    if (!replaced) {
        out.deinit(allocator);
        return source;
    }
    try out.appendSlice(allocator, source[start ..]);
    return out.toOwnedSlice(allocator);
}


fn match(source: []const u8, start: usize) ?class.Text {
    const range = ranges[source[start]];
    for (dictionary[range.start..range.end]) |entry| if (std.mem.startsWith(u8, source[start ..], entry.chinese)) return entry;
    return null;
}


const dictionary = [_]class.Text{
    .{ .chinese = "。同一请求不能混合显式名称模式与批量前后缀模式；目标存在时不会覆盖。", .english = " — a single request cannot mix explicit names with bulk prefix/suffix mode; existing targets are not overwritten.", .portuguese = " — uma mesma requisição não pode misturar nomes explícitos com o modo de prefixo/sufixo em lote; destinos existentes não são sobrescritos." },
    .{ .chinese = "。设置密码后，先提交表单登录，再携带服务端返回的", .english = ". After setting a password, submit the form login first, then carry the", .portuguese = ". Depois de definir uma senha, faça o login pelo formulário e use o" },
    .{ .chinese = "。搜索受服务器端深度、文件数、读取量和", .english = ". Searches are protected by server-side limits on depth, file count, read volume, and a", .portuguese = ". As pesquisas são protegidas por limites do servidor de profundidade, quantidade de arquivos, volume de leitura e um limite de" },
    .{ .chinese = "、绝对路径和越界路径会被拒绝。", .english = "and absolute or out-of-bounds paths are rejected.", .portuguese = "e caminhos absolutos ou fora dos limites são rejeitados." },
    .{ .chinese = "。命令行客户端应保存并发送", .english = ". A command-line client should store and send the", .portuguese = ". Um cliente de linha de comando deve salvar e enviar o" },
    .{ .chinese = "、重复分隔符或盘符路径。", .english = ", repeated separators, or drive-letter paths.", .portuguese = ", separadores repetidos ou caminhos com letra de unidade." },
    .{ .chinese = "。先发送一次", .english = ". Send", .portuguese = ". Envie" },
    .{ .chinese = "。请求中的", .english = ". The", .portuguese = ". O" },
    .{ .chinese = "、路径、", .english = ", path, ", .portuguese = ", caminho, " },
    .{ .chinese = "。会话", .english = ". The session", .portuguese = ". A sessão" },
    .{ .chinese = "、", .english = ", ", .portuguese = ", " },
    .{ .chinese = "。", .english = ".", .portuguese = "." },
    .{ .chinese = "不同时，文件保存到存储目录根位置，", .english = "differ, files are saved at the root of the store directory, and ", .portuguese = "forem diferentes, os arquivos são salvos na raiz do diretório de armazenamento, e " },
    .{ .chinese = "作为归档根；目录内部结构会保留。", .english = "as the archive root; the internal directory structure is preserved.", .portuguese = "como raiz do arquivo; a estrutura interna dos diretórios é preservada." },
    .{ .chinese = "下的单个名称，不包含目录路径。", .english = "and do not contain a directory path.", .portuguese = "e não contêm um caminho de diretório." },
    .{ .chinese = "上传或公告请求体超过配置限制", .english = "The upload or announcement request body exceeds the configured limit", .portuguese = "O corpo da requisição de envio ou de aviso excede o limite configurado" },
    .{ .chinese = "不要使用空路径、绝对路径、", .english = "Do not use empty paths, absolute paths,", .portuguese = "Não use caminhos vazios, caminhos absolutos," },
    .{ .chinese = "下载。每个所选项目都以自身", .english = "— each selected item uses its own", .portuguese = "— cada item selecionado usa o próprio" },
    .{ .chinese = "从后端获取公告板内容异常", .english = "Failed to fetch the announcement board content from the server", .portuguese = "Falha ao obter o conteúdo do quadro de avisos do servidor" },
    .{ .chinese = "上传失败，可以直接重试", .english = "Upload failed, you can retry directly", .portuguese = "O envio falhou, você pode tentar novamente" },
    .{ .chinese = "保存公告内容。该功能受", .english = "Save the announcement content. This feature depends on the", .portuguese = "Salva o conteúdo do aviso. Este recurso depende do" },
    .{ .chinese = "不参与共享目录定位。", .english = "does not take part in locating items in the shared directory.", .portuguese = "não participa da localização no diretório compartilhado." },
    .{ .chinese = "上传一个或多个文件", .english = "Upload one or more files", .portuguese = "Enviar um ou mais arquivos" },
    .{ .chinese = "上传未全部成功：", .english = "Some uploads failed: ", .portuguese = "Nem todos os envios foram concluídos: " },
    .{ .chinese = "作为下一次请求的", .english = "as the", .portuguese = "como o" },
    .{ .chinese = "中创建一个目录。", .english = "you can create a directory.", .portuguese = "CurrentDir você pode criar um diretório." },
    .{ .chinese = "上传文件异常：", .english = "Failed to upload files: ", .portuguese = "Falha ao enviar os arquivos: " },
    .{ .chinese = "下载文件异常", .english = "Failed to download files", .portuguese = "Falha ao baixar os arquivos" },
    .{ .chinese = "保存公告内容", .english = "Save the announcement content", .portuguese = "Salvar o conteúdo do aviso" },
    .{ .chinese = "一个时辰前", .english = "a few hours ago", .portuguese = "há algumas horas" },
    .{ .chinese = "上传已取消", .english = "Upload cancelled", .portuguese = "Envio cancelado" },
    .{ .chinese = "修改时间：", .english = "Modified: ", .portuguese = "Modificado em: " },
    .{ .chinese = "不同路径中", .english = "Two items in different paths with the same", .portuguese = "Dois itens em caminhos diferentes com o mesmo" },
    .{ .chinese = "一分钟前", .english = "a minute ago", .portuguese = "há um minuto" },
    .{ .chinese = "三分钟前", .english = "3 minutes ago", .portuguese = "há 3 minutos" },
    .{ .chinese = "一刻钟前", .english = "a quarter of an hour ago", .portuguese = "há um quarto de hora" },
    .{ .chinese = "一小时前", .english = "an hour ago", .portuguese = "há uma hora" },
    .{ .chinese = "个文件，", .english = "files, ", .portuguese = "arquivos, " },
    .{ .chinese = "上传成功", .english = "Upload complete", .portuguese = "Envio concluído" },
    .{ .chinese = "一天前", .english = "a day ago", .portuguese = "há um dia" },
    .{ .chinese = "两天前", .english = "2 days ago", .portuguese = "há 2 dias" },
    .{ .chinese = "三天前", .english = "3 days ago", .portuguese = "há 3 dias" },
    .{ .chinese = "一周前", .english = "a week ago", .portuguese = "há uma semana" },
    .{ .chinese = "个结果", .english = "results", .portuguese = "resultados" },
    .{ .chinese = "个文件", .english = "files", .portuguese = "arquivos" },
    .{ .chinese = "不能是", .english = "of a specific file item cannot be", .portuguese = "de um item de arquivo específico não pode ser" },
    .{ .chinese = "不影响", .english = "does not affect the structure inside the", .portuguese = "não afeta a estrutura" },
    .{ .chinese = "上传", .english = "Upload", .portuguese = "Enviar" },
    .{ .chinese = "下载", .english = "Download", .portuguese = "Baixar" },
    .{ .chinese = "今天", .english = "Today", .portuguese = "Hoje" },
    .{ .chinese = "使用", .english = "Use", .portuguese = "Use" },
    .{ .chinese = "与", .english = "and", .portuguese = "e" },
    .{ .chinese = "为", .english = "is", .portuguese = "igual a" },
    .{ .chinese = "决定目标相对路径，允许创建中间目录。目标已经存在时不会覆盖，并在逐项结果中返回失败。", .english = "decides the target relative path and allows creating intermediate directories. If the target already exists it is not overwritten, and a failure is returned in the per-item results.", .portuguese = "define o caminho relativo de destino e permite criar diretórios intermediários. Se o destino já existir, ele não é sobrescrito e uma falha é retornada nos resultados por item." },
    .{ .chinese = "必须为空。新名称按照请求数组顺序生成；文件保留原扩展名，目录不追加扩展名。", .english = "of every item must be empty. New names are generated in the order of the request array; files keep their original extension, and directories get no extension appended.", .portuguese = "de todos os itens deve estar vazio. Os novos nomes são gerados na ordem do array da requisição; os arquivos mantêm a extensão original e os diretórios não recebem extensão." },
    .{ .chinese = "在选定文件或目录中搜索名称及可识别的文本内容。返回路径相对于", .english = "Search names and recognizable text content in the selected files or directories. Returned paths are relative to", .portuguese = "Pesquisa nomes e conteúdo de texto reconhecível nos arquivos ou diretórios selecionados. Os caminhos retornados são relativos a" },
    .{ .chinese = "全部文件操作失败，通常是目标冲突或操作失败", .english = "All file operations failed, usually due to a target conflict or a failed operation", .portuguese = "Todas as operações de arquivo falharam, geralmente por conflito de destino ou falha na operação" },
    .{ .chinese = "删除一个或多个文件或目录。根目录", .english = "Delete one or more files or directories. The root directory", .portuguese = "Exclui um ou mais arquivos ou diretórios. O diretório raiz" },
    .{ .chinese = "将公告板的内容发送到后端异常", .english = "Failed to send the announcement board content to the server", .portuguese = "Falha ao enviar o conteúdo do quadro de avisos para o servidor" },
    .{ .chinese = "删除成功，但刷新文件列表失败", .english = "Deleted successfully, but refreshing the file list failed", .portuguese = "Excluído com sucesso, mas falha ao atualizar a lista de arquivos" },
    .{ .chinese = "存储、归档或服务器内部错误", .english = "Storage, archive, or internal server error", .portuguese = "Erro de armazenamento, de arquivamento ou interno do servidor" },
    .{ .chinese = "删除不可恢复，请始终检查", .english = "Deletion cannot be undone; always check the", .portuguese = "A exclusão não pode ser desfeita; sempre verifique o" },
    .{ .chinese = "列表。不存在的文件返回", .english = "listing. A missing file returns", .portuguese = "listagem. Um arquivo inexistente retorna" },
    .{ .chinese = "半小时前（星期一）", .english = "half an hour ago (Monday)", .portuguese = "há meia hora (segunda-feira)" },
    .{ .chinese = "刷新文件列表异常", .english = "Failed to refresh the file list", .portuguese = "Falha ao atualizar a lista de arquivos" },
    .{ .chinese = "单个或批量重命名", .english = "Rename a single item or in bulk", .portuguese = "Renomear um item ou em lote" },
    .{ .chinese = "单个或显式重命名", .english = "Single or explicit rename", .portuguese = "Renomeação individual ou explícita" },
    .{ .chinese = "创建文件夹异常", .english = "Failed to create the folder", .portuguese = "Falha ao criar a pasta" },
    .{ .chinese = "删除文件或目录", .english = "Delete files or directories", .portuguese = "Excluir arquivos ou diretórios" },
    .{ .chinese = "复制文件或目录", .english = "Copy files or directories", .portuguese = "Copiar arquivos ou diretórios" },
    .{ .chinese = "共享目录已变化", .english = "The shared directory has changed", .portuguese = "O diretório compartilhado foi alterado" },
    .{ .chinese = "将所选项目写入", .english = "Write the selected items into a", .portuguese = "Grava os itens selecionados em um" },
    .{ .chinese = "建议刷新重试", .english = "please refresh and try again", .portuguese = "atualize a página e tente novamente" },
    .{ .chinese = "删除文件异常", .english = "Failed to delete files", .portuguese = "Falha ao excluir os arquivos" },
    .{ .chinese = "创建登录会话", .english = "Create a login session", .portuguese = "Criar uma sessão de login" },
    .{ .chinese = "列出目录内容", .english = "List directory contents", .portuguese = "Listar o conteúdo do diretório" },
    .{ .chinese = "复制与移动", .english = "Copy and move", .portuguese = "Copiar e mover" },
    .{ .chinese = "对应功能被", .english = "The feature is disabled by the", .portuguese = "O recurso está desativado pela opção" },
    .{ .chinese = "半小时前", .english = "half an hour ago", .portuguese = "há meia hora" },
    .{ .chinese = "半个月前", .english = "half a month ago", .portuguese = "há meio mês" },
    .{ .chinese = "创建目录", .english = "Create directory", .portuguese = "Criar diretório" },
    .{ .chinese = "并跳转到", .english = "and redirects to", .portuguese = "e redireciona para" },
    .{ .chinese = "内结构。", .english = "archive.", .portuguese = "interna." },
    .{ .chinese = "在已有的", .english = "Inside an existing", .portuguese = "Dentro de um" },
    .{ .chinese = "半天前", .english = "half a day ago", .portuguese = "há meio dia" },
    .{ .chinese = "图片）", .english = "photo)", .portuguese = "foto)" },
    .{ .chinese = "已找到", .english = "Found", .portuguese = "Encontrados" },
    .{ .chinese = "处结果", .english = "results", .portuguese = "resultados" },
    .{ .chinese = "已加载", .english = "loaded", .portuguese = "carregados" },
    .{ .chinese = "待上传", .english = "Pending", .portuguese = "Pendentes" },
    .{ .chinese = "已上传", .english = "Uploaded", .portuguese = "Enviado" },
    .{ .chinese = "公告板", .english = "Announcement board", .portuguese = "Quadro de avisos" },
    .{ .chinese = "分钟。", .english = "minutes.", .portuguese = "minutos." },
    .{ .chinese = "可以是", .english = "can be", .portuguese = "pode ser" },
    .{ .chinese = "响应：", .english = "Response:", .portuguese = "Resposta:" },
    .{ .chinese = "字段。", .english = "field of each result.", .portuguese = "campo de cada resultado." },
    .{ .chinese = "全选", .english = "Select all", .portuguese = "Selecionar tudo" },
    .{ .chinese = "属性", .english = "Properties", .portuguese = "Propriedades" },
    .{ .chinese = "公告", .english = "Announcement", .portuguese = "Aviso" },
    .{ .chinese = "删除", .english = "Delete", .portuguese = "Excluir" },
    .{ .chinese = "复制", .english = "Copy", .portuguese = "Copiar" },
    .{ .chinese = "关于", .english = "About", .portuguese = "Sobre" },
    .{ .chinese = "取消", .english = "Cancel", .portuguese = "Cancelar" },
    .{ .chinese = "刚刚", .english = "just now", .portuguese = "agora mesmo" },
    .{ .chinese = "号）", .english = "number)", .portuguese = "número)" },
    .{ .chinese = "图片", .english = "photo", .portuguese = "foto" },
    .{ .chinese = "含义", .english = "Meaning", .portuguese = "Significado" },
    .{ .chinese = "和", .english = "and", .portuguese = "e" },
    .{ .chinese = "当", .english = "When", .portuguese = "Quando" },
    .{ .chinese = "号", .english = "", .portuguese = "" },
    .{ .chinese = "时表示已达到扫描预算，需缩小范围或关键字后重试。", .english = "and that means the scan budget has been reached; narrow the scope or the keyword and try again.", .portuguese = "e isso significa que o orçamento de varredura foi atingido; reduza o escopo ou a palavra-chave e tente novamente." },
    .{ .chinese = "搜索达到扫描上限，请缩小范围或关键字后重试。", .english = "Search reached the scan limit. Narrow the scope or the keyword and try again.", .portuguese = "A pesquisa atingiu o limite de varredura. Reduza o escopo ou a palavra-chave e tente novamente." },
    .{ .chinese = "是目标目录。目标已存在时，服务端自动使用", .english = "is the target directory. If the target already exists, the server automatically uses", .portuguese = "é o diretório de destino. Se o destino já existir, o servidor usa automaticamente" },
    .{ .chinese = "没有找到相关结果，请尝试其他搜索？", .english = "No matching results were found. Try another search?", .portuguese = "Nenhum resultado encontrado. Tentar outra pesquisa?" },
    .{ .chinese = "搜索分页位置异常，建议刷新重试", .english = "Invalid search pagination offset, please refresh and try again", .portuguese = "Posição de paginação da pesquisa inválida, atualize a página e tente novamente" },
    .{ .chinese = "文件操作通常返回逐项结果数组：", .english = "File operations usually return a per-item result array:", .portuguese = "As operações de arquivo geralmente retornam um array de resultados por item:" },
    .{ .chinese = "批量文件操作部分成功、部分失败", .english = "Bulk file operations partially succeeded and partially failed", .portuguese = "Operações em lote parcialmente bem-sucedidas e parcialmente com falha" },
    .{ .chinese = "未登录访问受保护路由时返回", .english = "When not logged in, accessing a protected route returns", .portuguese = "Sem login, acessar uma rota protegida retorna" },
    .{ .chinese = "拖拽文件（夹）或选择文件", .english = "Drag files or folders here, or choose files", .portuguese = "Arraste arquivos ou pastas, ou escolha os arquivos" },
    .{ .chinese = "是单个目录名称，不能包含", .english = "is a single directory name and cannot contain", .portuguese = "é um único nome de diretório e não pode conter" },
    .{ .chinese = "未登录，重定向到登录页", .english = "Not logged in; redirect to the login page", .portuguese = "Não autenticado; redireciona para a página de login" },
    .{ .chinese = "服务器返回了空压缩包", .english = "The server returned an empty archive", .portuguese = "O servidor retornou um arquivo compactado vazio" },
    .{ .chinese = "按名称和文本内容搜索", .english = "Search by name and text content", .portuguese = "Pesquisar por nome e conteúdo de texto" },
    .{ .chinese = "时默认为共享根目录。", .english = "is omitted, it defaults to the shared root directory.", .portuguese = "é omitido, o padrão é o diretório raiz compartilhado." },
    .{ .chinese = "文件响应根据类型使用", .english = "File responses use", .portuguese = "As respostas de arquivo usam" },
    .{ .chinese = "批量模式下所有项目的", .english = "In bulk mode, the", .portuguese = "No modo em lote, o" },
    .{ .chinese = "文件夹名称不能为空", .english = "The folder name cannot be empty", .portuguese = "O nome da pasta não pode ficar vazio" },
    .{ .chinese = "查看目录或读取文件", .english = "Browse a directory or read a file", .portuguese = "Navegar em um diretório ou ler um arquivo" },
    .{ .chinese = "查询指定目录。省略", .english = "Query the specified directory. When", .portuguese = "Consulta o diretório especificado. Quando" },
    .{ .chinese = "握手或请求参数无效", .english = "handshake or request parameters are invalid", .portuguese = "handshake ou parâmetros da requisição inválidos" },
    .{ .chinese = "新的名字不能为空", .english = "The new name cannot be empty", .portuguese = "O novo nome não pode ficar vazio" },
    .{ .chinese = "打包下载多个项目", .english = "Download multiple items as an archive", .portuguese = "Baixar vários itens em um arquivo compactado" },
    .{ .chinese = "文件或页面不存在", .english = "The file or page does not exist", .portuguese = "O arquivo ou a página não existe" },
    .{ .chinese = "新建文件夹名称", .english = "New folder name", .portuguese = "Nome da nova pasta" },
    .{ .chinese = "正在读取文件夹", .english = "Reading folder", .portuguese = "Lendo a pasta" },
    .{ .chinese = "时，接口不要求", .english = "is not set, the API does not require a", .portuguese = "não está definido, a API não exige um" },
    .{ .chinese = "接口使用请求头", .english = "endpoints use the request header", .portuguese = "interfaces usam o cabeçalho" },
    .{ .chinese = "按钮开关控制。", .english = "button toggle.", .portuguese = "botão correspondente." },
    .{ .chinese = "搜索文件异常", .english = "Failed to search files", .portuguese = "Falha ao pesquisar arquivos" },
    .{ .chinese = "正在取消上传", .english = "Cancelling the upload", .portuguese = "Cancelando o envio" },
    .{ .chinese = "旧的名字：", .english = "Old name: ", .portuguese = "Nome antigo: " },
    .{ .chinese = "批量前缀（", .english = "Batch prefix (", .portuguese = "Prefixo em lote (" },
    .{ .chinese = "批量后缀（", .english = "Batch suffix (", .portuguese = "Sufixo em lote (" },
    .{ .chinese = "正在搜索中", .english = "Searching", .portuguese = "Pesquisando" },
    .{ .chinese = "文件个数：", .english = "File count: ", .portuguese = "Quantidade de arquivos: " },
    .{ .chinese = "查看与下载", .english = "Viewing and downloading", .portuguese = "Visualização e download" },
    .{ .chinese = "是源项目，", .english = "is the source item, and", .portuguese = "é o item de origem, e" },
    .{ .chinese = "批量重命名", .english = "Bulk rename", .portuguese = "Renomeação em lote" },
    .{ .chinese = "新的名字", .english = "New name", .portuguese = "Novo nome" },
    .{ .chinese = "搜索结果", .english = "Results", .portuguese = "Resultados da pesquisa" },
    .{ .chinese = "文件列表", .english = "File list", .portuguese = "Lista de arquivos" },
    .{ .chinese = "文件属性", .english = "File properties", .portuguese = "Propriedades dos arquivos" },
    .{ .chinese = "批量下载", .english = "Batch download", .portuguese = "Download em lote" },
    .{ .chinese = "星期日", .english = "Sunday", .portuguese = "domingo" },
    .{ .chinese = "星期一", .english = "Monday", .portuguese = "segunda-feira" },
    .{ .chinese = "星期二", .english = "Tuesday", .portuguese = "terça-feira" },
    .{ .chinese = "星期三", .english = "Wednesday", .portuguese = "quarta-feira" },
    .{ .chinese = "星期四", .english = "Thursday", .portuguese = "quinta-feira" },
    .{ .chinese = "星期五", .english = "Friday", .portuguese = "sexta-feira" },
    .{ .chinese = "星期六", .english = "Saturday", .portuguese = "sábado" },
    .{ .chinese = "未设置", .english = "When", .portuguese = "Quando" },
    .{ .chinese = "搜索", .english = "Search", .portuguese = "Pesquisar" },
    .{ .chinese = "更多", .english = "More", .portuguese = "Mais" },
    .{ .chinese = "新建", .english = "New folder", .portuguese = "Nova pasta" },
    .{ .chinese = "改名", .english = "Rename", .portuguese = "Renomear" },
    .{ .chinese = "放置", .english = "Drop", .portuguese = "Soltar" },
    .{ .chinese = "找到", .english = "Found", .portuguese = "Encontrados" },
    .{ .chinese = "毫秒", .english = "ms", .portuguese = "ms" },
    .{ .chinese = "文档", .english = "Documentation", .portuguese = "Documentação" },
    .{ .chinese = "方法", .english = "Method", .portuguese = "Método" },
    .{ .chinese = "或", .english = "or", .portuguese = "ou" },
    .{ .chinese = "等可用名称，不覆盖已有项目。目录不能复制或移动到自身内部。", .english = "and other available names, without overwriting existing items. A directory cannot be copied or moved into itself.", .portuguese = "e outros nomes disponíveis, sem sobrescrever itens existentes. Um diretório não pode ser copiado ou movido para dentro de si mesmo." },
    .{ .chinese = "监听共享目录变化。握手请求同样需要有效会话", .english = "to watch the shared directory for changes. The handshake request also requires a valid session", .portuguese = "para monitorar alterações no diretório compartilhado. A requisição de handshake também exige uma sessão" },
    .{ .chinese = "相同的两个项目不能同时打包，否则返回", .english = "cannot be packed together, otherwise the server returns", .portuguese = "não podem ser compactados juntos, caso contrário o servidor retorna" },
    .{ .chinese = "符号链接不会作为普通共享项目处理。", .english = "Symbolic links are not treated as regular shared items.", .portuguese = "Links simbólicos não são tratados como itens compartilhados comuns." },
    .{ .chinese = "目录发生变化时，服务端发送：", .english = "When the directory changes, the server sends:", .portuguese = "Quando o diretório muda, o servidor envia:" },
    .{ .chinese = "确定删除么？无法恢复的哦", .english = "Delete anyway? This cannot be undone", .portuguese = "Confirmar a exclusão? Não será possível recuperar" },
    .{ .chinese = "登录成功，跳转到首页", .english = "Login succeeded; redirect to the home page", .portuguese = "Login bem-sucedido; redireciona para a página inicial" },
    .{ .chinese = "监听共享目录变化", .english = "Watch the shared directory for changes", .portuguese = "Monitorar alterações no diretório compartilhado" },
    .{ .chinese = "状态和每个结果的", .english = "status and the", .portuguese = "status e o" },
    .{ .chinese = "移动文件或目录", .english = "Move files or directories", .portuguese = "Mover arquivos ou diretórios" },
    .{ .chinese = "粘贴文件异常", .english = "Failed to paste files", .portuguese = "Falha ao colar os arquivos" },
    .{ .chinese = "移动文件异常", .english = "Failed to move files", .portuguese = "Falha ao mover os arquivos" },
    .{ .chinese = "网络连接中断", .english = "Network connection interrupted", .portuguese = "Conexão de rede interrompida" },
    .{ .chinese = "目录变化监听", .english = "Directory change watching", .portuguese = "Monitoramento de alterações no diretório" },
    .{ .chinese = "登录成功返回", .english = "A successful login returns", .portuguese = "Um login bem-sucedido retorna" },
    .{ .chinese = "秒时限保护。", .english = "second time limit.", .portuguese = "segundos." },
    .{ .chinese = "登录密码错误", .english = "Wrong login password", .portuguese = "Senha de login incorreta" },
    .{ .chinese = "累计大小：", .english = "Total size: ", .portuguese = "Tamanho total: " },
    .{ .chinese = "登录与会话", .english = "Login and sessions", .portuguese = "Login e sessões" },
    .{ .chinese = "结果名称为", .english = "The resulting names are", .portuguese = "Os nomes resultantes são" },
    .{ .chinese = "点击打开", .english = "Click to open", .portuguese = "Clique para abrir" },
    .{ .chinese = "登录页面", .english = "Login page", .portuguese = "Página de login" },
    .{ .chinese = "状态码", .english = "Status codes", .portuguese = "Códigos de status" },
    .{ .chinese = "编码。", .english = "encoded.", .portuguese = "codificado." },
    .{ .chinese = "移动", .english = "Move", .portuguese = "Mover" },
    .{ .chinese = "终端", .english = "Terminal", .portuguese = "Terminal" },
    .{ .chinese = "确定", .english = "OK", .portuguese = "OK" },
    .{ .chinese = "粘贴", .english = "Paste", .portuguese = "Colar" },
    .{ .chinese = "目录", .english = "Contents", .portuguese = "Índice" },
    .{ .chinese = "用途", .english = "Purpose", .portuguese = "Finalidade" },
    .{ .chinese = "维护", .english = "maintenance", .portuguese = "manutenção" },
    .{ .chinese = "状态", .english = "Status", .portuguese = "Status" },
    .{ .chinese = "秒", .english = "s", .portuguese = "s" },
    .{ .chinese = "计算所选文件和目录的总数量、总大小及最近修改时间。", .english = "Compute the total count, total size, and latest modification time of the selected files and directories.", .portuguese = "Calcula a quantidade total, o tamanho total e a última modificação dos arquivos e diretórios selecionados." },
    .{ .chinese = "读取文件或浏览目录。路径中的每个片段都应进行", .english = "Read a file or browse a directory. Every segment in the path must be", .portuguese = "Ler um arquivo ou navegar em um diretório. Cada segmento do caminho deve ser" },
    .{ .chinese = "路径相对于共享目录，根目录写作", .english = "Paths are relative to the shared directory; the root directory is written as", .portuguese = "Os caminhos são relativos ao diretório compartilhado; o diretório raiz é escrito como" },
    .{ .chinese = "读取当前公告，不需要请求体。", .english = "Read the current announcement; no request body is required.", .portuguese = "Lê o aviso atual; nenhum corpo de requisição é necessário." },
    .{ .chinese = "请勾选需要搜索的文件或目录", .english = "Please check the files or folders you want to search", .portuguese = "Selecione os arquivos ou pastas que deseja pesquisar" },
    .{ .chinese = "请求成功，文件操作全部成功", .english = "Request succeeded; all file operations succeeded", .portuguese = "Requisição bem-sucedida; todas as operações de arquivo foram concluídas" },
    .{ .chinese = "请勾选需要下载的文件", .english = "Please check the files you want to download", .portuguese = "Selecione os arquivos que deseja baixar" },
    .{ .chinese = "请选中需要复制的文件", .english = "Please select the files you want to copy", .portuguese = "Selecione os arquivos que deseja copiar" },
    .{ .chinese = "请勾选需要删除的文件", .english = "Please check the files you want to delete", .portuguese = "Selecione os arquivos que deseja excluir" },
    .{ .chinese = "请选择需要移动的文件", .english = "Please select the files you want to move", .portuguese = "Selecione os arquivos que deseja mover" },
    .{ .chinese = "请勾选需要改名的文件", .english = "Please check the files you want to rename", .portuguese = "Selecione os arquivos que deseja renomear" },
    .{ .chinese = "请勾选查看属性的文件", .english = "Please check the files whose properties you want to view", .portuguese = "Selecione os arquivos cujas propriedades deseja ver" },
    .{ .chinese = "输入有效搜索内容", .english = "Enter a valid search term", .portuguese = "Digite um termo de pesquisa válido" },
    .{ .chinese = "读取文件夹异常：", .english = "Failed to read the folder: ", .portuguese = "Falha ao ler a pasta: " },
    .{ .chinese = "获取文件属性异常", .english = "Failed to read file properties", .portuguese = "Falha ao obter as propriedades dos arquivos" },
    .{ .chinese = "计算文件属性", .english = "Compute file properties", .portuguese = "Calcular as propriedades dos arquivos" },
    .{ .chinese = "读取公告内容", .english = "Read the announcement content", .portuguese = "Ler o conteúdo do aviso" },
    .{ .chinese = "获取下一页；", .english = "of the next request to get the next page;", .portuguese = "da próxima requisição para obter a próxima página;" },
    .{ .chinese = "请上传文件", .english = "Please choose files to upload", .portuguese = "Escolha os arquivos para enviar" },
    .{ .chinese = "请求类型为", .english = "The request type is", .portuguese = "O tipo da requisição é" },
    .{ .chinese = "路由总览", .english = "Route overview", .portuguese = "Visão geral das rotas" },
    .{ .chinese = "请求约定", .english = "Request conventions", .portuguese = "Convenções de requisição" },
    .{ .chinese = "设置了", .english = "sets", .portuguese = "define" },
    .{ .chinese = "耗时", .english = "Elapsed", .portuguese = "Tempo" },
    .{ .chinese = "路径", .english = "Path", .portuguese = "Caminho" },
    .{ .chinese = "调用", .english = "to call the", .portuguese = "para chamar a" },
    .{ .chinese = "非根目录列表的第一项是用于返回上级的特殊项目", .english = "The first item of a non-root listing is the special item used to go up one level:", .portuguese = "O primeiro item de uma listagem que não é a raiz é o item especial usado para voltar um nível:" },
    .{ .chinese = "部分文件上传失败", .english = "Some files failed to upload", .portuguese = "Alguns arquivos falharam no envio" },
    .{ .chinese = "页面路由还包括", .english = "Page routes also include", .portuguese = "As rotas de página também incluem" },
    .{ .chinese = "重命名异常", .english = "Failed to rename", .portuguese = "Falha ao renomear" },
    .{ .chinese = "配置禁用", .english = "configuration", .portuguese = "correspondente." },
    .{ .chinese = "重命名", .english = "Rename", .portuguese = "Renomear" },
    .{ .chinese = "通过", .english = "Use", .portuguese = "Use" },
    .{ .chinese = "都是", .english = "are both single names under", .portuguese = "são ambos nomes únicos em" },
    .{ .chinese = "，同时注意不要把登录页面误当作接口结果。", .english = ", and must not mistake the login page for an API result.", .portuguese = ", e não confunda a página de login com um resultado da API." },
    .{ .chinese = "，随后为每个文件重复发送", .english = " once, then repeat the following for each file:", .portuguese = " uma vez e, em seguida, repita o seguinte para cada arquivo:" },
    .{ .chinese = "；具体文件项目的", .english = "; the", .portuguese = "; o" },
    .{ .chinese = "；目录响应为简单", .english = "; directory responses are a simple", .portuguese = "; as respostas de diretório são uma simples" },
    .{ .chinese = "，并重定向到", .english = ", and redirects to", .portuguese = ", e redireciona para" },
    .{ .chinese = "，子项目写作", .english = ", and a child item is written as", .portuguese = ", e um item filho é escrito como" },
    .{ .chinese = "，有效期为", .english = ", and is valid for", .portuguese = ", e é válida por" },
    .{ .chinese = "，并以", .english = ", and download it as", .portuguese = ", e baixe-o como" }
};
