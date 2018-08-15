<?php

echo '<h2>whoami? ' . shell_exec('whoami') . '</h2>';

$file = new \SplFileObject('/tmp/temptestfile', "w");
$written = $file->fwrite('readable content');

echo "Wrote $written bytes to file: " . $file->getPathname();
