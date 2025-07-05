<?php
//***************************************
// This is downloaded from www.plus2net.com //
/// You can distribute this code with the link to www.plus2net.com ///
//  Please don't  remove the link to www.plus2net.com ///
// This is for your learning only not for commercial use. ///////
//The author is not responsible for any type of loss or problem or damage on using this script.//
/// You can use it at your own risk. /////
//*****************************************

$pdo = require 'connect.php';

// start working with the database


if (!$pdo) {
    echo "Error: Unable to open database\n";
    echo "<br>";
}

?>

<!doctype html public "-//w3c//dtd html 3.2//en">

<html>

<head>
<title>Demo of EasyBob Web Interface</title>
<SCRIPT language=JavaScript>
function reload(form)
{
var val=form.cat.options[form.cat.options.selectedIndex].value;
self.location='easybob.php?cat=' + val ;
}
function reload3(form)
{
var val=form.cat.options[form.cat.options.selectedIndex].value;
var val2=form.subcat.options[form.subcat.options.selectedIndex].value;

self.location='easybob.php?cat=' + val + '&cat3=' + val2 ;
}

</script>
</head>

<body>
<h1>EasyBob, the friendly software installation bot!</h1>
<?php

///////// Getting the module names from the module table for first list box//////////
$quer2="select distinct id,module from module order by module;";
///////////// End of query for first list box////////////

/////// for second drop down list we will check if category is selected else we will display all the subcategory///// 
$cat=$_GET['cat']; // This line is added to take care if your global variable is off
if(isset($cat) and strlen($cat) > 0){
$quer="select distinct sn.sw_name, ec.sw_name_id from ec_name ec inner join sw_name sn on ec.sw_name_id=sn.id inner join module m on ec.module_id=m.id where m.id=$cat order by sw_name";
	}else{$quer="SELECT DISTINCT subcategory,subcat_id FROM subcategory order by subcategory"; }
 
////////// end of query for second subcategory drop down list box ///////////////////////////

/////// for Third drop down list we will check if sub category is selected else we will display all the subcategory3///// 
$cat3=$_GET['cat3']; // This line is added to take care if your global variable is off
if(isset($cat3) and strlen($cat3) > 0){
$quer3="select sw_name, sv.sw_version, tn.toolchain, tv.toolchain_version, ec.ec_name, sn.sw_description, sw_url, sn.sw_cite from ec_name ec inner join sw_version sv on ec.sw_version_id=sv.id  inner join toolchain tn on ec.toolchain_id=tn.id inner join toolchain_version tv on ec.toolchain_version_id=tv.id inner join sw_name sn on ec.sw_name_id=sn.id where sw_name_id=$cat3;"; 
}else{$quer3="SELECT DISTINCT subcat2 FROM subcategory2 order by subcat2"; } 
////////// end of query for third subcategory drop down list box ///////////////////////////

echo "<form method=post name=f1 action='reset.php'>";
//////////        Starting of first drop downlist /////////
echo "<select name='cat' onchange=\"reload(this.form)\">\n<option>Select Module</option>\n";
foreach ($pdo->query($quer2) as $noticia2) {
if($noticia2['id']==@$cat){echo "<option selected value='$noticia2[id]'>$noticia2[module]</option>\n";}
else{echo  "<option value='$noticia2[id]'>$noticia2[module]</option>\n";}
}
echo "</select>";
echo "\n";
//////////////////  This will end the first drop down list ///////////

//////////        Starting of second drop downlist /////////
echo "<select name='subcat' onchange=\"reload3(this.form)\">\n<option>Select Software</option>\n";
foreach ($pdo->query($quer) as $noticia) {
if($noticia['sw_name_id']==@$cat3){echo "<option selected value='$noticia[sw_name_id]'>$noticia[sw_name]</option>\n";}
else{echo  "<option value='$noticia[sw_name_id]'>$noticia[sw_name]</option>\n";}
}
echo "</select>";
echo "\n";
//////////////////  This will end the second drop down list ///////////

//////////        Starting of third drop downlist /////////
echo "<select name='subcat3'>";
echo "<option selected>Select software version and toolchain</option>";
foreach ($pdo->query($quer3) as $noticia) {
echo  "<option value='$noticia[ec_name]'>$noticia[sw_version]-$noticia[toolchain]-$noticia[toolchain_version]</option>\n";
}
echo "</select>";
//////////////////  This will end the third drop down list ///////////
echo "\n";
echo "<input type=submit value='Submit the form data'></form>";


/////////////////  This is for additional information //////
echo "<h3>Additional information:</h3>";

foreach ($pdo->query($quer3) as $layer) {
if(isset($layer['sw_url'])) {
		echo "The homepage of ".$layer['sw_name']." is: <br><a href=".$layer['sw_url'].">".$layer['sw_url']."</a><br><br>";
	} 
if(isset($layer['sw_description'])) {
		echo "The description is: <br>".$layer['sw_description']."<br><br>";
	} 
if(isset($layer['sw_cite'])) {
		echo "Citation Information: ".$layer['sw_cite'];
	} 
break;
}

?>

<br><br>
<a href=easybob.php>Reset and Try again</a>
<br><br>
</body>
</html>

