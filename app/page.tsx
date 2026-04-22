import Link from 'next/link';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-gray-50 text-gray-900">
      <div className="max-w-2xl text-center space-y-6 bg-white p-12 rounded-2xl shadow-sm border border-gray-100">
        <h1 className="text-4xl font-bold tracking-tight">Repository Cloned</h1>
        <p className="text-lg text-gray-600">
          The GitHub repository <code className="bg-gray-100 px-2 py-1 rounded text-sm text-blue-600">peyton2465/Dex</code> has been successfully cloned.
        </p>
        <p className="text-gray-500">
          You can find all the files (including <code className="bg-gray-100 px-1 py-0.5 rounded text-sm">main.lua</code> and <code className="bg-gray-100 px-1 py-0.5 rounded text-sm">build.py</code>) in the <span className="font-semibold">/Dex</span> folder via the file explorer.
        </p>
      </div>
    </main>
  );
}
