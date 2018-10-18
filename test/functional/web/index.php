<?php

$testFile = isset($_GET['testFile']) && $_GET['testFile'] === 'true' ? true : false;

if ($testFile === true) {
    echo '<h2>whoami? ' . shell_exec('whoami') . '</h2>';

    $file = new \SplFileObject('/tmp/temptestfile', "w");
    $written = $file->fwrite('readable content');
    
    echo "Wrote $written bytes to file: " . $file->getPathname();

    exit;
}

phpinfo();
