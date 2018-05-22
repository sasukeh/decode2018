<html>

<body>
	<center>
		<br>
		<br>
		<br>
		<p>
			<img src="./mslogo.png" alt="">
		</p>
		<br>
		<font color="gray" size="7"> Welcome to XXXXXXXXXXXXX </font>
		<br>
		<font color="gray" size="5">
			<%= (new java.util.Date()).toLocaleString() %>
				<br>
				<% out.println("Hosted at " + request.getRemoteAddr());%>
					<p>
						<img src="./azurelogo.png" alt="">
					</p>
					This web site is powered by Azure
		</font>

	</center>
</body>

</html>