
import Base
import Base.IPv4

const CRLF = "\x0d\x0a"
const NICK = "jul14h"
const SERVER = "irc.elte.hu"
const PORT = 6667

type Connection
  host::Union(ASCIIString, IPv4)
  port::Integer
  socket::TcpSocket
end

function open(host::Union(IPv4, ASCIIString), port::Integer)
  host_ip::IPv4 = (isa(host, ASCIIString) ? Base.getaddrinfo(host) : host)
  socket = TcpSocket()
  Base.connect(socket, host_ip, port)
  conn = Connection(host, port, socket)
  return conn
end

function close(conn::Connection)
  Base.close(conn.socket)
end

function write(c::Connection, s::String)
  print("< $s")
  Base.write(c.socket, s)
end

function privmsg(socket::TcpSocket, to::String, msg::String)
 Base.write(socket, "PRIVMSG $to :$msg\n")
end

function reader(s::TcpSocket, nreadable::Int)
  input = strip(takebuf_string(s.buffer))
  println("$(int(Base.time()))> $input")
  if begins_with(input, "PING")
    Base.write(s, replace(input, "PING", "PONG"))
    return false
  end
  parts = split(input, " ")
  msg = ""
  from = ""
  reply_to = ""
  if length(parts) >= 4 && parts[2] == "PRIVMSG"
    msg = replace(join(parts[4:], " "), ":", "", 1)
    from = first(split(replace(parts[1], ":", "", 1), "!"))
    if parts[3] == NICK #privmsg
      reply_to = from
    else
      reply_to = parts[3]
    end
    if first(search(msg, NICK)) != 0
      privmsg(s, reply_to, "sup?")
    end
  end
  return false
end

function init()
  c = open(SERVER, PORT)
  write(c, "NICK $NICK\n")
  write(c, "USER $NICK $NICK $NICK :$NICK\n")
  start_reading(c.socket, reader)
  return c
end

c = init()

while true
  line = readline(STDIN)
  if strip(line) == ""
    break
  end
  ast = Base.parse_input_line(line)
  println(">> $(eval(ast))")
end

close(c)
