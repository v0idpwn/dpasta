import std.stdio;
import std.file;
import std.getopt;
import clipboard;
import core.stdc.stdlib : exit;
import gtk.Entry;
import gtk.MainWindow;

enum string WINDOW_NAME = "dpasta";
enum int WINDOW_WIDTH = 300;
enum int WINDOW_HEIGHT = 50;

int main(string[] args){
    bool config = false;
    bool gui = false;
    auto opt = getopt(
            args,
            "gtk", "Open GTK gui", &gui,
            "config", "Run in config mode", &config
            );
    if(opt.helpWanted){
        writeln("Use --config for your first run");
        writeln("Use --gtk for graphic mode");
        writeln("Pass the copypasta name as an argument");
    }
    if(config){
        string path = "~/dpasta";
        if(isDir(path)){
            writeln("Dpasta dir already exists. Put your copypastas into it!");
            exit(0);
        }
        writeln("Creating dpasta dir...");
        mkdir("~/dpasta");
        writeln("Creation complete. You're ready to use dpasta now. Just put some 
                .txt files in teh dir, right?");
        exit(0);
    }
    if(gui){
        import gtk.Label;
        import gtk.Main;
        import gtk.Button;
        import gtk.Box;
        import gtk.Widget;
        import gdk.Event;

        // Initializing GTK window
        Main.init(args);
        MainWindow win = new MainWindow(WINDOW_NAME);
        win.setDefaultSize(WINDOW_WIDTH, WINDOW_HEIGHT);

        // Creating components
        Box box = new Box(Orientation.VERTICAL, 0);
        Entry text_input = new Entry();
        Label label = new Label("Copypasta name:");
        Button btn = new Button("Copy!");

        // Adding events
        btn.addOnClicked(delegate void(Button b){btnPress(text_input, win);});
        win.addOnKeyPress(delegate bool(GdkEventKey* event, Widget widget){
            import gdk.Keysyms : GdkKeysyms;

            if(event.keyval == GdkKeysyms.GDK_Return){
                btnPress(text_input, win);
                return true;
            }
            return false;
        });

        // Adding and running
        box.add(label);
        box.add(text_input);
        box.add(btn);
        win.add(box);
        win.showAll();
        Main.run;
    }
    return 0;
}

void btnPress(Entry text_input, MainWindow win){
    import std.process;
    import std.array;
    import std.algorithm;
    import gtk.Label;
    import gtk.Box;

    auto filename = text_input.getText();
    auto base_path = "/home/v0idpwn/dpasta/";
    auto path = base_path ~ filename ~ ".txt"; 
    auto read = pipeProcess(["cat", path], Redirect.all);
    scope(exit){
        wait(read.pid);
    }
    auto file_content = cast(string)read.stdout.byChunk(4096).joiner().array;
    auto err = cast(string)read.stderr.byChunk(4096).joiner().array;
    if(err){
        import gtk.MessageDialog;
        MessageDialog d = new MessageDialog(win, GtkDialogFlags.MODAL, MessageType.ERROR, ButtonsType.OK, err);
        d.run();
        d.destroy();
        win.close();
    }else{
        writeClipboard(file_content);
        win.close();
    }
}
