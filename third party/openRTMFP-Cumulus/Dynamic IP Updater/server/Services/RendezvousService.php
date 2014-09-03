<?php
/**
 *  amfPHP service to provide rendezvous, UDP hole punching, NAT traversal, and other services.
 *
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 Patrick Bay
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE. 	 
 * 
 * @package SocialCastr_Services
 */

class RendezvousService {

    public function getPublicIP() {	
		$returnInfo = (object) "RendezvousService.getPublicIP.returnInfo";
		$returnInfo->server = $_SERVER;
		$returnInfo->session = $_SESSION;
		$returnInfo->cookies = $_COOKIE;
		$returnInfo->environment = $_ENV;
		$serverInfoXML  = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
		$serverInfoXML .= "<servers>";
		$serverInfoXML .= "   <server checkedin=\"".date("G:i:s;d:m:Y;TZ:P (e)")."\">".$_SERVER["REMOTE_ADDR"]."</server>";
		$serverInfoXML .= "</servers>";
		file_put_contents ("../rendezvous.xml", $serverInfoXML);
		return ($returnInfo);
    }//getPublicIP

}//RendezvousService
?>
