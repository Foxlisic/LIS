<?php

$in  = $argv[1];
$out = $argv[2] ?? str_replace('.asm', '.s', $in);

file_put_contents($out, join("\n", parse_file($in) ));

// Распарсить файл в том числе рекурсивно
function parse_file($in) {

    $res  = [];
    $rows = [];
    $alu  = ['add'=>'0x10','adc'=>'0x11','sub'=>'0x12','sbc'=>'0x13','and'=>'0x14','xor'=>'0x15','or'=>'0x16','cmp'=>'0x17'];
    $shr  = ['rol'=>'0x18','ror'=>'0x19','shl'=>'0x1A','shr'=>'0x1B','rcl'=>'0x1C','rcr'=>'0x1D',             'sar'=>'0x1F'];

    // Подрубка файлов
    foreach (file($in) as $row) {

        if (preg_match('~^(.*)include\s+"(.+)"~', $row, $c)) {
            $rows[] = $c[1];
            foreach (parse_file($c[2]) as $_) $rows[] = $_;
        } else {
            $rows[] = $row;
        }
    }

    // А теперь парсер подрубленных файлов
    foreach ($rows as $row) {

        // Убирать комментарии
        $row = trim(preg_replace('~;.*?$~', '', $row));

        // Обнаружить метки
        if (preg_match('~^\s*([^:]+:)\s*(.+)$~', $row, $c)) {
            $res[] = $c[1];
            $row   = $c[2];
        }

        // Необходимо для парсера
        $chk = preg_replace('~\s+~', '', strtolower($row));

        // Перемещения
        if (preg_match('~(movb|movd|movw)r(\d+),\[r(\d+)\]~', $chk, $c)) {
            $res[] = "db ".['movb'=>2,'movw'=>3,'movd'=>4][$c[1]].",{$c[3]},{$c[2]}";
        } else if (preg_match('~(movb|movd|movw)\[r(\d+)\],r(\d+)~', $chk, $c)) {
            $res[] = "db ".['movb'=>5,'movw'=>6,'movd'=>7][$c[1]].",{$c[3]},{$c[2]}";
        } else if (preg_match('~movr(\d+),r(\d+)~', $chk, $c)) {
            $res[] = "db 0x01,{$c[2]},{$c[1]}";
        } else if (preg_match('~movsr(\d+),(.+)~', $chk, $c)) {
            $res[] = "db 0x1E,{$c[1]},{$c[2]}";
        } else if (preg_match('~movr(\d+),(.+)~', $chk, $c)) {
            $res[] = "db 0x00,{$c[1]}";
            $res[] = "dd {$c[2]}";
        }
        // Арифметика
        else if (preg_match('~(mul|div)r(\d+),r(\d+)=>r(\d+),r(\d+)~', $chk, $c)) {
            $res[] = "db ".['mul'=>8,'div'=>9][$c[1]].",{$c[2]},{$c[3]},{$c[4]},{$c[5]}";
        } else if (preg_match('~mulr(\d+),r(\d+)=>r(\d+)~', $chk, $c)) {
            $res[] = "db 0x08,{$c[1]},{$c[2]},{$c[3]},{$c[3]}";
        } else if (preg_match('~(add|adc|sub|sbc|and|xor|or)r(\d+),r(\d+),r(\d+)~', $chk, $c)) {
            $res[] = "db ".$alu[$c[1]].",{$c[3]},{$c[4]},{$c[2]}"; // Расширенная версия
        } else if (preg_match('~(add|adc|sub|sbc|and|xor|or)r(\d+),r(\d+)~', $chk, $c)) {
            $res[] = "db ".$alu[$c[1]].",{$c[2]},{$c[3]},{$c[2]}"; // Сокращенная версия
        } else if (preg_match('~cmpr(\d+),r(\d+)~', $chk, $c)) {
            $res[] = "db 0x17,{$c[1]},{$c[2]}";
        } else if (preg_match('~(rol|ror|shl|shr|rcl|rcr|sar)r(\d+),r(\d+)~', $chk, $c)) {
            $res[] = "db ".$shr[$c[1]].",{$c[2]},{$c[3]}"; // Сокращенная версия
        }
        // Работа со стеком
        else if (preg_match('~(push|pop)(.+)~', $chk, $c)) {
            $cnt = explode(',', $c[2]);
            $res[] = "db ".["push"=>'0x0E','pop'=>'0x0F'][$c[1]].",".count($cnt).",".str_replace('r','', $c[2]);
        }
        // Переходы
        else if (preg_match('~jpr(\d+)~i', $chk, $c)) {
            $res[] = "db 0x7A,".$c[1];
        } else if (preg_match('~jr\s+(.+)~i', $row, $c)) {
            $res[] = "db 0x70";
            $res[] = "db ".$c[1]."-$-1";
        } else if (preg_match('~(jp|call)\s+(.+)~i', $row, $c)) {
            $res[] = "db ".['call'=>'0x0C','jp'=>'0x71'][$c[1]];
            $res[] = "dd {$c[2]}";
        } else if ($chk == 'ret') {
            $res[] = "db 0x0D";
        }
        // Условные переходы
        else if (preg_match('~(jc|jnc|jz|jnz|je|jne|jb|jnb|jbe|ja|js|jns|jl|jnl|jle|jg)\s+(.+)~', $row, $c)) {
            $res[] = $c[1]." short ".$c[2];
        }
        // Все остальное
        else {
            $res[] = $row;
        }
    }

    return array_filter($res, function($e) { return trim($e) != ''; });
}
