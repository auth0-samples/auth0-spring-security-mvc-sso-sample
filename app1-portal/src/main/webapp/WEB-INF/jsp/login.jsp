<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags"%>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>Login</title>
    <link rel="stylesheet" type="text/css" href="/css/bootstrap.css"/>
    <link rel="stylesheet" type="text/css" href="/css/jquery.growl.css"/>
    <script src="http://code.jquery.com/jquery.js"></script>
    <script src="http://cdn.auth0.com/js/lock-9.min.js"></script>
    <script src="http://cdn.auth0.com/w2/auth0-6.8.js"></script>
    <script src="/js/jquery.growl.js" type="text/javascript"></script>
</head>
<body>
<div class="container">
    <script type="text/javascript">
        // hide the page in case there is an SSO session (to avoid flickering)
        $('body').hide();
        $(function () {
            var auth0 = new Auth0({
                domain: '${domain}',
                clientID: '${clientId}',
                callbackURL: '${fn:replace(pageContext.request.requestURL, pageContext.request.requestURI, '')}${loginCallback}'
            });
            <sec:authorize var="authenticated" access="isAuthenticated()" />
            auth0.getSSOData(function (err, data) {
                if (data && data.sso === true) {
                    // have SSO session
                    console.log('SSO: an Auth0 SSO session already exists');
                    <c:choose>
                        <c:when test="${authenticated}">
                               var loggedIn = true;
                               var loggedInUserId = '${user.userId}';
                        </c:when>
                        <c:otherwise>
                                var loggedIn = false;
                                var loggedInUserId = '';
                        </c:otherwise>
                    </c:choose>
                    if (!loggedIn || (loggedInUserId !== data.lastUsedUserID)) {
                        // have SSO session but no valid local session - auto-login user
                        auth0.login({
                            scope: 'openid name email picture',
                            state: '${state}',
                            connection: '${connection}'
                        }, function (err) {
                            // this only gets called if there was a login error
                            console.error('Error logging in: ' + err);
                        });
                    } else {
                        // have SSO session and valid user - send to successfully authenticated landing page
                        window.location = '${fn:replace(pageContext.request.requestURL, pageContext.request.requestURI, '')}${loginRedirectOnSuccess}';
                    }
                } else {
                    <c:choose>
                        <c:when test="${authenticated}">
                            // have local session (autenticated locally), but no SSO session exists so log them out locally too - will force login page
                            window.location = '${fn:replace(pageContext.request.requestURL, pageContext.request.requestURI, '')}${logoutEndpoint}';
                        </c:when>
                        <c:otherwise>
                            // have no SSO session and are not authenticated locally - present Lock widget Login box
                            $('body').show();
                            var error = ${error};
                            if (error) {
                                $.growl.error({message: "Please log in"});
                            } else {
                                $.growl({title: "Welcome!", message: "Please log in"});
                            }
                            var lock = new Auth0Lock('${clientId}', '${domain}');
                            lock.showSignin({
                                dict: {
                                    signin: {
                                        title: "Portal Login"
                                    }
                                },
                                authParams: {
                                    state: '${state}',
                                    // change scopes to whatever you like
                                    // claims are added to JWT id_token - openid profile gives everything
                                    scope: 'openid roles user_id name nickname email picture'
                                },
                                sso: true,
                                connections: ['${connection}'],
                                responseType: 'code',
                                popup: false,
                                callbackURL: '${fn:replace(pageContext.request.requestURL, pageContext.request.requestURI, '')}${loginCallback}'
                            });
                        </c:otherwise>
                    </c:choose>
                }
            });
        });
    </script>
</div>
</body>
</html>
